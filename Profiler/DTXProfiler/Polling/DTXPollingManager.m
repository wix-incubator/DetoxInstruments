//
//  DTXPollingManager.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPollingManager.h"

@implementation DTXPollingManager
{
	NSTimeInterval _interval;
	
	dispatch_queue_t _measurementsTimerQueue;
	dispatch_source_t _measurementsTimer;
	
	NSMapTable<id<DTXPollable>, DTXPollableHandler>* _pollables;
}

- (instancetype)init
{
	return [self initWithInterval:0.5];
}

- (instancetype)initWithInterval:(NSTimeInterval)timeInterval
{
	self = [super init];
	
	if(self)
	{
		_interval = timeInterval;
		
		_pollables = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
		
		dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
		_measurementsTimerQueue = dispatch_queue_create("com.wix.DTXProfilerMeasurementsTimerQueue", qosAttribute);
		
		_measurementsTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _measurementsTimerQueue);
		uint64_t interval = timeInterval * NSEC_PER_SEC;
		dispatch_source_set_timer(_measurementsTimer, dispatch_walltime(NULL, 0), interval, interval / 10);
		__weak __typeof(self) weakSelf = self;
		
		dispatch_source_set_event_handler(_measurementsTimer, ^{
			[weakSelf _pollPollables];
		});
	}
	
	return self;
}

- (void)addPollable:(id<DTXPollable>)pollable handler:(DTXPollableHandler)handler
{
	[_pollables setObject:[handler copy] forKey:pollable];
}

- (void)resume
{
	dispatch_resume(_measurementsTimer);
}

- (void)suspend
{
	dispatch_suspend(_measurementsTimer);
}

- (void)_pollPollables
{
	for(id<DTXPollable> pollable in [[_pollables copy] keyEnumerator])
	{
		//Probably should actually measure time between pollings, but good enough for now.
		[pollable pollWithTimePassed:_interval];
		[_pollables objectForKey:pollable](pollable);
	}
}

- (void)dealloc
{
	dispatch_cancel(_measurementsTimer);
}

@end
