//
//  DTXMachUtilities.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 04/09/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXMachUtilities.h"

//More info here:
//	https://stackoverflow.com/questions/33143102/howto-get-the-correct-frame-pointer-of-an-arbitrary-thread-in-ios
//	https://stackoverflow.com/questions/6351229/how-to-loop-through-all-active-thread-in-ipad-app
//	https://github.com/kstenerud/KSCrash
//	https://github.com/bestswifter/BSBacktraceLogger

#if defined(__arm64__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(3UL))
#define DTX_THREAD_STATE_COUNT ARM_THREAD_STATE64_COUNT
#define DTX_THREAD_STATE ARM_THREAD_STATE64
#define DTX_FRAME_POINTER_REGISTER __fp
#define DTX_STACK_POINTER_REGISTER __sp
#define DTX_INSTRUCTION_ADDRESS_REGISTER __pc

#elif defined(__arm__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(1UL))
#define DTX_THREAD_STATE_COUNT ARM_THREAD_STATE_COUNT
#define DTX_THREAD_STATE ARM_THREAD_STATE
#define DTX_FRAME_POINTER_REGISTER __r[7]
#define DTX_STACK_POINTER_REGISTER __sp
#define DTX_INSTRUCTION_ADDRESS_REGISTER __pc

#elif defined(__x86_64__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) (A)
#define DTX_THREAD_STATE_COUNT x86_THREAD_STATE64_COUNT
#define DTX_THREAD_STATE x86_THREAD_STATE64
#define DTX_FRAME_POINTER_REGISTER __rbp
#define DTX_STACK_POINTER_REGISTER __rsp
#define DTX_INSTRUCTION_ADDRESS_REGISTER __rip

#elif defined(__i386__)

#define DTX_DETAG_INSTRUCTION_ADDRESS(A) (A)
#define DTX_THREAD_STATE_COUNT x86_THREAD_STATE32_COUNT
#define DTX_THREAD_STATE x86_THREAD_STATE32
#define DTX_FRAME_POINTER_REGISTER __ebp
#define DTX_STACK_POINTER_REGISTER __esp
#define DTX_INSTRUCTION_ADDRESS_REGISTER __eip

#endif

#define DTX_INSTRUCTION_FROM_RETURN_ADDRESS(A) (DTX_DETAG_INSTRUCTION_ADDRESS((A)) - 1)

typedef struct DTXStackFrameEntry
{
	const struct DTXStackFrameEntry *const previous;
	const uintptr_t return_address;
} DTXStackFrameEntry;

static const uint64_t __DTXMaxFrames = 2048;

static bool __DTXFillThreadStateIntoMachineContext(thread_t thread, _STRUCT_MCONTEXT *machineContext)
{
	mach_msg_type_number_t state_count = DTX_THREAD_STATE_COUNT;
	return thread_get_state(thread, DTX_THREAD_STATE, (thread_state_t)&machineContext->__ss, &state_count) == KERN_SUCCESS;
}

static uintptr_t __DTXReadFramePointerRegister(mcontext_t const machineContext)
{
	return machineContext->__ss.DTX_FRAME_POINTER_REGISTER;
}

static uintptr_t __DTXReadInstructionAddressRegister(mcontext_t const machineContext)
{
	return machineContext->__ss.DTX_INSTRUCTION_ADDRESS_REGISTER;
}

static uintptr_t __DTXReadLinkRegister(mcontext_t const machineContext)
{
#if defined(__i386__) || defined(__x86_64__)
	return 0;
#else
	return machineContext->__ss.__lr;
#endif
}

static kern_return_t __DTXReadMemorySafely(const void *const src, void *const dst, const size_t numBytes)
{
	vm_size_t bytesCopied = 0;
	return vm_read_overwrite(mach_task_self(), (vm_address_t)src, (vm_size_t)numBytes, (vm_address_t)dst, &bytesCopied);
}

NSArray<NSNumber*>* DTXCallStackSymbolsForMachThread(thread_act_t thread)
{
	NSMutableArray* rv = [NSMutableArray new];
	
	_STRUCT_MCONTEXT machineContext;
	if(!__DTXFillThreadStateIntoMachineContext(thread, &machineContext))
	{
		return nil;
	}
	
	const uintptr_t instructionAddress = __DTXReadInstructionAddressRegister(&machineContext);
	[rv addObject:@(instructionAddress)];
	
	uintptr_t linkRegister = __DTXReadLinkRegister(&machineContext);
	if (linkRegister)
	{
		[rv addObject:@(linkRegister)];
	}
	
	DTXStackFrameEntry frame = {0};
	const uintptr_t framePtr = __DTXReadFramePointerRegister(&machineContext);
	if(framePtr == 0 || __DTXReadMemorySafely((void *)framePtr, &frame, sizeof(frame)) != KERN_SUCCESS)
	{
		return nil;
	}
	
	while(rv.count < __DTXMaxFrames)
	{
		uintptr_t addr = frame.return_address;
		if(frame.return_address == 0 || frame.previous == 0 || __DTXReadMemorySafely(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS)
		{
			break;
		}
		
		[rv addObject:@(DTX_INSTRUCTION_FROM_RETURN_ADDRESS(addr))];
	}
	
	if(instructionAddress == 0)
	{
		return nil;
	}
	
	return rv;
}
