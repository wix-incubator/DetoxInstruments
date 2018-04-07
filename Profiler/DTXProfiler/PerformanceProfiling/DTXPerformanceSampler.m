//
//  DTXPerformanceSampler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPerformanceSampler.h"
@import Darwin;
#import <execinfo.h>
#import "DTXMachUtilities.h"
#import "DTXFPSCalculator.h"

@implementation DTXThreadMeasurement @end
@implementation DTXCPUMeasurement @end

static void* __symbols[2048];

typedef void *rusage_info_t;
extern int proc_pid_rusage(int pid, int flavor, rusage_info_t *buffer) __OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0);

@interface DTXPerformanceSampler ()

@property (nonatomic, strong) DTXFPSCalculator *fpsCalculator;

@property (nonatomic, strong) DTXCPUMeasurement* currentCPU;
@property (nonatomic, assign) double currentMemory;
@property (nonatomic, assign) double currentFPS;
@property (nonatomic, assign) uint64_t currentDiskReads;
@property (nonatomic, assign) uint64_t currentDiskReadsDelta;
@property (nonatomic, assign) uint64_t currentDiskWrites;
@property (nonatomic, assign) uint64_t currentDiskWritesDelta;

@end

@implementation DTXPerformanceSampler
{
	BOOL _collectStackTraces;
	BOOL _collectThreadInfo;
}

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	self = [super init];
	
	if(self)
	{
		_collectStackTraces = configuration.collectStackTraces;
		_collectThreadInfo = configuration.recordThreadInformation;
		
		self.fpsCalculator = [DTXFPSCalculator new];
	}
	
	return self;
}

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	[self.fpsCalculator pollWithTimePassed:interval];
	
	self.currentFPS = self.fpsCalculator.fps;
	
	// Update CPU measurements
	self.currentCPU = self.cpu;
	
	// Update memory measurements
	self.currentMemory = self.memory;
	
	uint64_t dr = self.diskReads;
	self.currentDiskReadsDelta = dr - _currentDiskReads;
	self.currentDiskReads = dr;
	
	uint64_t dw = self.diskWrites;
	self.currentDiskWritesDelta = dw - _currentDiskWrites;
	self.currentDiskWrites = dw;
	
	if(_collectStackTraces)
	{
		NSArray* symbolsArray;
		if(self.currentCPU.heaviestThread.machThread != mach_thread_self())
		{
			if(thread_suspend(self.currentCPU.heaviestThread.machThread) == KERN_SUCCESS)
			{
				symbolsArray = DTXCallStackSymbolsForMachThread(self.currentCPU.heaviestThread.machThread);
				thread_resume(self.currentCPU.heaviestThread.machThread);
			}
			else
			{
				//Thread is already invalid, no stack trace.
				symbolsArray = @[];
			}
		}
		else
		{
			NSMutableArray* mutableSymbolsArray = [NSMutableArray new];
			int symbolCount = backtrace(__symbols, 2048);
			
			for(uint32_t idx = 0; idx < symbolCount; idx++)
			{
				[mutableSymbolsArray addObject:@((uintptr_t)__symbols[idx])];
			}
			
			symbolsArray = mutableSymbolsArray;
		}
		
		_callStackSymbols = symbolsArray;
	}
}

#pragma mark - CPU

- (DTXCPUMeasurement*)cpu
{
	task_info_data_t taskInfo;
	mach_msg_type_number_t taskInfoCount = TASK_INFO_MAX;
	if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)taskInfo, &taskInfoCount) != KERN_SUCCESS)
	{
		return nil;
	}
	
	thread_array_t threadList;
	mach_msg_type_number_t threadCount;
	thread_info_data_t threadInfo;
	
	if (task_threads(mach_task_self(), &threadList, &threadCount) != KERN_SUCCESS)
	{
		return nil;
	}
	double totalCpu = 0;
	
	DTXCPUMeasurement* rv = [DTXCPUMeasurement new];
	NSMutableArray* threads = [NSMutableArray new];
	
	double maxCPU = -1;
	DTXThreadMeasurement* heaviestThread;
	
	mach_port_t self_thread = mach_thread_self();
	
	for (int threadIndex = 0; threadIndex < threadCount; threadIndex++)
	{
		if(threadList[threadIndex] == self_thread)
		{
			continue;
		}
		
		mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
		if (thread_info(threadList[threadIndex], THREAD_EXTENDED_INFO, (thread_info_t)threadInfo, &threadInfoCount) != KERN_SUCCESS)
		{
			return nil;
		}
		
		thread_extended_info_t threadExtendedInfo = (thread_extended_info_t)threadInfo;
		
		if (!(threadExtendedInfo->pth_flags & TH_FLAGS_IDLE))
		{
			totalCpu += (threadExtendedInfo->pth_cpu_usage / (double)TH_USAGE_SCALE);
			
			if(_collectThreadInfo)
			{
				DTXThreadMeasurement* thread = [DTXThreadMeasurement new];
				thread.machThread = threadList[threadIndex];
				thread.cpu = threadExtendedInfo->pth_cpu_usage / (double)TH_USAGE_SCALE;
				thread.name = [NSString stringWithUTF8String:threadExtendedInfo->pth_name];
				
				if (thread_info(threadList[threadIndex], THREAD_IDENTIFIER_INFO, (thread_info_t)threadInfo, &threadInfoCount) != KERN_SUCCESS)
				{
					return nil;
				}
				
				thread_identifier_info_t threadIdentifier = (thread_identifier_info_t)threadInfo;
				
				thread.identifier = threadIdentifier->thread_id;
				
				[threads addObject:thread];
				
				if(thread.cpu > maxCPU)
				{
					maxCPU = thread.cpu;
					heaviestThread = thread;
				}
			}
		}
	}
	vm_deallocate(mach_task_self(), (vm_offset_t)threadList, threadCount * sizeof(thread_t));
	
	rv.threads = threads;
	rv.totalCPU = totalCpu;
	rv.heaviestThread = heaviestThread;
	
	return rv;
}

#pragma mark - Memory

- (CGFloat)memory
{
	struct task_basic_info taskInfo;
	mach_msg_type_number_t taskInfoCount = sizeof(taskInfo);
	kern_return_t result = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&taskInfo, &taskInfoCount);
	return result == KERN_SUCCESS ? taskInfo.resident_size : 0;
}

- (void)simulateMemoryWarning
{
	NSAssert([NSThread isMainThread], @"Must be called on main thread.");
	
	// Making sure to minimize the risk of rejecting app because of the private API.
	NSString *key = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char []){0x5f, 0x70, 0x65, 0x72, 0x66, 0x6f, 0x72, 0x6d, 0x4d, 0x65, 0x6d, 0x6f, 0x72, 0x79, 0x57, 0x61, 0x72, 0x6e, 0x69, 0x6e, 0x67} length:21] encoding:NSASCIIStringEncoding];
	SEL selector = NSSelectorFromString(key);
	id object = [UIApplication sharedApplication];
	((void (*)(id, SEL))[object methodForSelector:selector])(object, selector);
}

#pragma mark - Disk IO

- (uint64_t)diskReads
{
	struct rusage_info_v3 usage_info;
	
	if(proc_pid_rusage([NSProcessInfo processInfo].processIdentifier, RUSAGE_INFO_V3, (rusage_info_t*)&usage_info) != KERN_SUCCESS)
	{
		return 0;
	}
	
	return usage_info.ri_diskio_bytesread;
}

- (uint64_t)diskWrites
{
	struct rusage_info_v3 usage_info;
	
	if(proc_pid_rusage([NSProcessInfo processInfo].processIdentifier, RUSAGE_INFO_V3, (rusage_info_t*)&usage_info) != KERN_SUCCESS)
	{
		return 0;
	}
	
	return usage_info.ri_diskio_byteswritten;
}

@end
