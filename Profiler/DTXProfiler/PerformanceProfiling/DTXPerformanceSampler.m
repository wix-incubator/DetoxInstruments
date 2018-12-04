//
//  DTXPerformanceSampler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPerformanceSampler.h"
@import Darwin;
#import "DTXMachUtilities.h"
#import "DTXFPSCalculator.h"

#import "dtx_libproc.h"

@implementation DTXThreadMeasurement @end
@implementation DTXCPUMeasurement @end

static void* __symbols[DTXMaxFrames];

@interface DTXPerformanceSampler ()

@property (nonatomic, strong) DTXFPSCalculator *fpsCalculator;

@property (nonatomic, strong) DTXCPUMeasurement* currentCPU;
@property (nonatomic, assign) uint64_t currentMemory;
@property (nonatomic, assign) double currentFPS;
@property (nonatomic, assign) uint64_t currentDiskReads;
@property (nonatomic, assign) uint64_t currentDiskReadsDelta;
@property (nonatomic, assign) uint64_t currentDiskWrites;
@property (nonatomic, assign) uint64_t currentDiskWritesDelta;
@property (nonatomic, strong) NSArray<NSString*>* currentOpenFiles;

@end

@implementation DTXPerformanceSampler
{
	BOOL _collectStackTraces;
	BOOL _collectThreadInfo;
	BOOL _collectOpenFiles;
	
	uint64_t _initialDiskReads;
	uint64_t _initialDiskWrites;
}

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	self = [super init];
	
	if(self)
	{
		_collectStackTraces = configuration.collectStackTraces;
		_collectThreadInfo = configuration.recordThreadInformation;
		_collectOpenFiles = configuration.collectOpenFileNames;
		
		self.fpsCalculator = [DTXFPSCalculator new];
		
		_DTXDiskUsage(&_initialDiskReads, &_initialDiskWrites);
	}
	
	return self;
}

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	[self.fpsCalculator pollWithTimePassed:interval];
	
	self.currentFPS = self.fpsCalculator.fps;
	
	// Update CPU measurements
	self.currentCPU = _DTXCPUUsage(_collectThreadInfo);
	
	// Update memory measurements
	self.currentMemory = _DTXMemoryUsage();
	
	uint64_t dr, dw;
	_DTXDiskUsage(&dr, &dw);
	dr -= _initialDiskReads;
	dw -= _initialDiskWrites;
	
	self.currentDiskReadsDelta = dr - _currentDiskReads;
	self.currentDiskReads = dr;
	
	self.currentDiskWritesDelta = dw - _currentDiskWrites;
	self.currentDiskWrites = dw;
	
	if(_collectOpenFiles)
	{
		self.currentOpenFiles = self.openFiles;
	}
	else
	{
		self.currentOpenFiles = nil;
	}
	
	if(_collectStackTraces)
	{
		const thread_act_t heaviestThread = self.currentCPU.heaviestThread.machThread;
		NSMutableArray* mutableSymbolsArray = [NSMutableArray new];
		int symbolCount = 0;
		
		symbolCount = DTXCallStackSymbolsForMachThread(heaviestThread, __symbols);
		
		for(int idx = 0; idx < symbolCount; idx++)
		{
			[mutableSymbolsArray addObject:@((uintptr_t)__symbols[idx])];
		}
		
		_callStackSymbols = mutableSymbolsArray;
	}
}

#pragma mark - CPU

DTX_ALWAYS_INLINE
static DTXCPUMeasurement* _DTXCPUUsage(BOOL collectThreadInfo)
{
	task_info_data_t task_info_data;
	mach_msg_type_number_t task_info_count = TASK_INFO_MAX;
	if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)task_info_data, &task_info_count) != KERN_SUCCESS)
	{
		return nil;
	}
	
	thread_array_t thread_list;
	mach_msg_type_number_t thread_count;
	thread_info_data_t thread_info_data;
	
	if (task_threads(mach_task_self(), &thread_list, &thread_count) != KERN_SUCCESS)
	{
		return nil;
	}
	double total_cpu = 0;
	
	DTXCPUMeasurement* rv = [DTXCPUMeasurement new];
	NSMutableArray* threads = [NSMutableArray new];
	
	double max_cpu = -1;
	DTXThreadMeasurement* heaviestThread;
	
	mach_port_t thread_self = mach_thread_self();
	
	for (mach_msg_type_number_t thread_idx = 0; thread_idx < thread_count; thread_idx++)
	{
		if(thread_list[thread_idx] == thread_self)
		{
			continue;
		}
		
		mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
		if (thread_info(thread_list[thread_idx], THREAD_EXTENDED_INFO, (thread_info_t)thread_info_data, &thread_info_count) != KERN_SUCCESS)
		{
			return nil;
		}
		
		thread_extended_info_t thread_extended_info = (thread_extended_info_t)thread_info_data;
		
//		if (!(thread_extended_info->pth_flags & TH_FLAGS_IDLE))
//		{
			total_cpu += (thread_extended_info->pth_cpu_usage / (double)TH_USAGE_SCALE);
			
			if(collectThreadInfo)
			{
				DTXThreadMeasurement* thread = [DTXThreadMeasurement new];
				thread.machThread = thread_list[thread_idx];
				thread.cpu = thread_extended_info->pth_cpu_usage / (double)TH_USAGE_SCALE;
				thread.name = [NSString stringWithUTF8String:thread_extended_info->pth_name];
				
				if (thread_info(thread_list[thread_idx], THREAD_IDENTIFIER_INFO, (thread_info_t)thread_info_data, &thread_info_count) != KERN_SUCCESS)
				{
					return nil;
				}
				
				thread_identifier_info_t threadIdentifier = (thread_identifier_info_t)thread_info_data;
				
				thread.identifier = threadIdentifier->thread_id;
				
				[threads addObject:thread];
				
				if(thread.cpu > max_cpu)
				{
					max_cpu = thread.cpu;
					heaviestThread = thread;
				}
			}
//		}
	}
	vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
	
	rv.threads = threads;
	rv.totalCPU = total_cpu;
	rv.heaviestThread = heaviestThread;
	
	return rv;
}

#pragma mark - Memory

DTX_ALWAYS_INLINE
static uint64_t _DTXMemoryUsage(void)
{
	struct task_vm_info task_vm_info;
	mach_msg_type_number_t vmInfoCount = sizeof(task_vm_info);
	kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&task_vm_info, &vmInfoCount);
	return result == KERN_SUCCESS ? task_vm_info.internal + task_vm_info.compressed : 0;
}

#pragma mark - Disk IO

DTX_ALWAYS_INLINE
static void _DTXDiskUsage(uint64_t* reads, uint64_t* writes)
{
	struct rusage_info_v3 usage_info;
	if(proc_pid_rusage([NSProcessInfo processInfo].processIdentifier, RUSAGE_INFO_V3, (rusage_info_t*)&usage_info) != KERN_SUCCESS)
	{
		*reads = 0;
		*writes = 0;
	}
	
	*reads = usage_info.ri_diskio_bytesread;
	*writes = usage_info.ri_diskio_byteswritten;
}

- (NSArray<NSString*>*)openFiles
{
	pid_t pid = getpid();
	struct proc_fdinfo fd_info[1024];
	int buffer_size = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fd_info, 1024);
	int numberOfProcFDs = buffer_size / PROC_PIDLISTFD_SIZE;
	
	NSMutableArray* openFiles = [NSMutableArray new];
	
	for(int i = 0; i < numberOfProcFDs; i++)
	{
		if(fd_info[i].proc_fdtype == PROX_FDTYPE_VNODE) {
			struct vnode_fdinfowithpath vnode_info;
			proc_pidfdinfo(pid, fd_info[i].proc_fd, PROC_PIDFDVNODEPATHINFO, &vnode_info, PROC_PIDFDVNODEPATHINFO_SIZE);
			[openFiles addObject:[NSString stringWithUTF8String:vnode_info.pvip.vip_path]];
		}
	}
	
	return openFiles;
}

@end
