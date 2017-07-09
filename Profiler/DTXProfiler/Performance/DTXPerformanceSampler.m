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

static dispatch_semaphore_t __stackTraceSem;
//static NSArray<NSNumber*>* __callStackSymbols;

static void* __symbols[2048];
static uint32_t __symbolCount;

void DTXStackTraceSignalHandler(int signr, siginfo_t *info, void *secret)
{
	__symbolCount = backtrace(__symbols, 2048);
	
	dispatch_semaphore_signal(__stackTraceSem);
}

__attribute__((constructor))
static void __DTXInitializePerformanceSampler()
{
	__stackTraceSem = dispatch_semaphore_create(0);
	
	struct sigaction sa;
	sigfillset(&sa.sa_mask);
	sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = DTXStackTraceSignalHandler;
	sigaction(SIGPROF, &sa, NULL);
}

@implementation DTXPerformanceSampler
{
	BOOL _collectStackTraces;
}

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	self = [super init];
	
	if(self)
	{
		_performanceToolkit = [[DBPerformanceToolkit alloc] initWithConfiguration:configuration];
		_collectStackTraces = configuration.collectStackTraces;
	}
	
	return self;
}

/**
 * This is abusing internal API to overcome pthread_kill restriction on worker queue threads. See:
 * @ref https://stackoverflow.com/questions/44990839/pthread-kill-to-a-gcd-managed-thread/
 * @ref https://github.com/apple/darwin-libpthread/blob/master/src/pthread.c#L1348
 *
 * TODO: Use mach API to achieve this properly.
 */
extern int __pthread_kill(mach_port_t, int);

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	[_performanceToolkit pollWithTimePassed:interval];
	
	if(_collectStackTraces)
	{
		int x = __pthread_kill(_performanceToolkit.currentCPU.heaviestThread.machThread, SIGPROF);
		if(x == 0)
		{
			dispatch_semaphore_wait(__stackTraceSem, DISPATCH_TIME_FOREVER);
			
			NSMutableArray* symbols = [NSMutableArray new];
			
			for(uint32_t idx = 2; idx < __symbolCount; idx++)
			{
				[symbols addObject:@((NSUInteger)__symbols[idx])];
			}
			
			_callStackSymbols = symbols;
		}
	}
}

@end
