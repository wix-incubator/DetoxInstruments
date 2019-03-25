//
//  DTXFPSCalculator.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 3/25/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXFPSCalculator.h"
@import Darwin;

static const CGFloat DBFPSCalculatorTargetFramerate = 60.0;

@interface DTXFPSCalculator ()
{
	atomic_ulong _frameCount;
	atomic_bool _enabled;
}

@property (nonatomic, strong) CADisplayLink *displayLink;

//Handle last known fps - must use synchronized access for thread safety
@property (nonatomic, strong) dispatch_queue_t lastKnownFPSQueue;
@property (nonatomic, assign) CGFloat lastKnownFPS;

@end

@implementation DTXFPSCalculator

#pragma mark - Initialization

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		[self setupFPSMonitoring];
		[self setupNotifications];
	}
	
	return self;
}

- (void)dealloc
{
	[self.displayLink setPaused:YES];
	[self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - FPS Monitoring

- (void)setupFPSMonitoring
{
	self.lastKnownFPSQueue = dispatch_queue_create("com.wix.DTXProfilerLastKnownFPSQueue", DISPATCH_QUEUE_SERIAL);
	
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick)];
	[self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
	__block BOOL enabled = NO;
	
	void (^block)(void) = ^{
		if([UIApplication sharedApplication] && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
		{
			enabled = YES;
		}
	};
	
	if(NSThread.isMainThread == YES)
	{
		block();
	}
	else
	{
		dispatch_sync(dispatch_get_main_queue(), block);
	}
	
	if(enabled)
	{
		atomic_store(&_enabled, YES);
	}
	else
	{
		[self.displayLink setPaused:YES];
	}
}

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	if(atomic_load(&_enabled) == NO)
	{
		dispatch_sync(_lastKnownFPSQueue, ^ {
			self.lastKnownFPS = 0;
		});
		
		return;
	}
	
	uint64_t frameCount = atomic_exchange(&_frameCount, 0);
	CGFloat fps = MIN(frameCount / interval, DBFPSCalculatorTargetFramerate);
	
	dispatch_sync(_lastKnownFPSQueue, ^{
		self.lastKnownFPS = fps;
	});
}

- (void)displayLinkTick
{
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	atomic_fetch_add(&_frameCount, 1);
#else
	_frameCount++;
#endif
	}

#pragma mark - Notifications

- (void)setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(applicationDidBecomeActiveNotification:)
												 name: UIApplicationDidBecomeActiveNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(applicationWillResignActiveNotification:)
												 name: UIApplicationWillResignActiveNotification
											   object: nil];
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
	atomic_exchange(&_frameCount, 0);
	[self.displayLink setPaused:NO];
	atomic_store(&_enabled, YES);
}


- (void)applicationWillResignActiveNotification:(NSNotification *)notification
{
	[self.displayLink setPaused:YES];
	atomic_store(&_enabled, NO);
}

#pragma mark - FPS

- (CGFloat)fps
{
	__block CGFloat fps;
	
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	dispatch_sync(_lastKnownFPSQueue, ^{
#endif
		fps = self.lastKnownFPS;
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	});
#endif
	
	return fps;
}

@end
