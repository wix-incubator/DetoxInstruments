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

static void* __symbols[2048];

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

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	[_performanceToolkit pollWithTimePassed:interval];
	
	if(_collectStackTraces)
	{
		NSArray* symbolsArray;
		if(_performanceToolkit.currentCPU.heaviestThread.machThread != mach_thread_self())
		{
			if(thread_suspend(_performanceToolkit.currentCPU.heaviestThread.machThread) == KERN_SUCCESS)
			{
				symbolsArray = DTXCallStackSymbolsForMachThread(_performanceToolkit.currentCPU.heaviestThread.machThread);
				thread_resume(_performanceToolkit.currentCPU.heaviestThread.machThread);
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

@end
