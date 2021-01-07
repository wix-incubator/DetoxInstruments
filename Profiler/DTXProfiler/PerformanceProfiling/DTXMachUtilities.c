//
//  DTXMachUtilities.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 04/09/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXMachUtilities.h"
#import <execinfo.h>

//More info here:
//	https://stackoverflow.com/questions/33143102/howto-get-the-correct-frame-pointer-of-an-arbitrary-thread-in-ios
//	https://stackoverflow.com/questions/6351229/how-to-loop-through-all-active-thread-in-ipad-app
//	https://github.com/kstenerud/KSCrash
//	https://github.com/bestswifter/BSBacktraceLogger

#if defined(__arm64__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(3UL))
#define DTX_THREAD_STATE_COUNT ARM_THREAD_STATE64_COUNT
#define DTX_THREAD_STATE ARM_THREAD_STATE64

#define DTX_MACHINE_CONTEXT_GET_FRAME_POINTER(mc) ((void*)__darwin_arm_thread_state64_get_fp(mc->__ss))
#define DTX_MACHINE_CONTEXT_GET_PROGRAM_COUNTER(mc) ((void*)__darwin_arm_thread_state64_get_pc(mc->__ss))
#define DTX_MACHINE_CONTEXT_GET_LINK_REGISTER(mc) ((void*)__darwin_arm_thread_state64_get_lr(mc->__ss))

#elif defined(__arm__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(1UL))
#define DTX_THREAD_STATE_COUNT ARM_THREAD_STATE_COUNT
#define DTX_THREAD_STATE ARM_THREAD_STATE

#define DTX_MACHINE_CONTEXT_GET_FRAME_POINTER(mc) ((void*)mc->__ss.__r[7])
#define DTX_MACHINE_CONTEXT_GET_PROGRAM_COUNTER(mc) ((void*)mc->__ss.__pc)
#define DTX_MACHINE_CONTEXT_GET_LINK_REGISTER(mc) ((void*)mc->__ss.__lr)

#elif defined(__x86_64__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) (A)
#define DTX_THREAD_STATE_COUNT x86_THREAD_STATE64_COUNT
#define DTX_THREAD_STATE x86_THREAD_STATE64

#define DTX_MACHINE_CONTEXT_GET_FRAME_POINTER(mc) ((void*)mc->__ss.__rbp)
#define DTX_MACHINE_CONTEXT_GET_PROGRAM_COUNTER(mc) ((void*)mc->__ss.__rip)
#define DTX_MACHINE_CONTEXT_GET_LINK_REGISTER(mc) ((void*)0)

#elif defined(__i386__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) (A)
#define DTX_THREAD_STATE_COUNT x86_THREAD_STATE32_COUNT
#define DTX_THREAD_STATE x86_THREAD_STATE32

#define DTX_MACHINE_CONTEXT_GET_FRAME_POINTER(mc) ((void*)mc->__ss.__ebp)
#define DTX_MACHINE_CONTEXT_GET_PROGRAM_COUNTER(mc) ((void*)mc->__ss.__eip)
#define DTX_MACHINE_CONTEXT_GET_LINK_REGISTER(mc) ((void*)0)

#endif

#define DTX_INSTRUCTION_FROM_RETURN_ADDRESS(A) (DTX_DETAG_INSTRUCTION_ADDRESS((A)) - 1)

typedef struct DTXStackFrameEntry
{
	const struct DTXStackFrameEntry *const previous;
	const uintptr_t return_address;
} DTXStackFrameEntry;

DTX_ALWAYS_INLINE
static bool __DTXFillThreadStateIntoMachineContext(thread_t thread, _STRUCT_MCONTEXT *machineContext)
{
	mach_msg_type_number_t state_count = DTX_THREAD_STATE_COUNT;
	return thread_get_state(thread, DTX_THREAD_STATE, (thread_state_t)&machineContext->__ss, &state_count) == KERN_SUCCESS;
}

DTX_ALWAYS_INLINE
static void* __DTXReadFramePointerRegister(mcontext_t const machineContext)
{
	return DTX_MACHINE_CONTEXT_GET_FRAME_POINTER(machineContext);
}

DTX_ALWAYS_INLINE
static void* __DTXReadInstructionAddressRegister(mcontext_t const machineContext)
{
	return DTX_MACHINE_CONTEXT_GET_PROGRAM_COUNTER(machineContext);
}

DTX_ALWAYS_INLINE
static void* __DTXReadLinkRegister(mcontext_t const machineContext)
{
	return DTX_MACHINE_CONTEXT_GET_LINK_REGISTER(machineContext);
}

DTX_ALWAYS_INLINE
static kern_return_t __DTXReadMemorySafely(const void *const src, void *const dst, const size_t numBytes)
{
	vm_size_t bytesCopied = 0;
	return vm_read_overwrite(mach_task_self(), (vm_address_t)src, (vm_size_t)numBytes, (vm_address_t)dst, &bytesCopied);
}

int __DTXCallStackSymbolsForMacThreadInternal_modern(thread_act_t thread, void** symbols, int size)
{
	return 0;
}

DTX_ALWAYS_INLINE
int __DTXCallStackSymbolsForMacThreadInternal(thread_act_t thread, void** buffer, int size)
{
	int count = 0;
	
	_STRUCT_MCONTEXT machineContext;
	if(!__DTXFillThreadStateIntoMachineContext(thread, &machineContext))
	{
		return count;
	}
	
	void* instructionAddress = __DTXReadInstructionAddressRegister(&machineContext);
	buffer[count++] = instructionAddress;
	
	void* linkRegister = __DTXReadLinkRegister(&machineContext);
	if (linkRegister)
	{
		buffer[count++] = linkRegister;
	}
	
	DTXStackFrameEntry frame = {0};
	const void* framePtr = __DTXReadFramePointerRegister(&machineContext);
	
	if(framePtr == 0 || __DTXReadMemorySafely((void *)framePtr, &frame, sizeof(frame)) != KERN_SUCCESS)
	{
		return 0;
	}

	while(count < size)
	{
		void* addr = (void*)frame.return_address;
		if(frame.return_address == 0 || frame.previous == 0 || __DTXReadMemorySafely(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS)
		{
			break;
		}

		buffer[count++] = (void*)DTX_INSTRUCTION_FROM_RETURN_ADDRESS((uintptr_t)addr);
	}
	
	if(instructionAddress == 0)
	{
		return 0;
	}
	
	return count;
}

int DTXCallStackSymbolsForMachThread(thread_act_t thread, void** buffer, int size)
{
	int symbolCount = 0;
	if(thread != mach_thread_self())
	{
		if(thread_suspend(thread) == KERN_SUCCESS)
		{
			symbolCount = __DTXCallStackSymbolsForMacThreadInternal(thread, buffer, size);
			thread_resume(thread);
			return symbolCount;
		}
	}
	else
	{
		symbolCount = backtrace(buffer, size);
	}
	
	return symbolCount;
}
