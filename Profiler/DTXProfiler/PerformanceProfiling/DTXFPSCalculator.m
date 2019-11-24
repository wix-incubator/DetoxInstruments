//
//  DTXFPSCalculator.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 3/25/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXFPSCalculator.h"
@import Darwin;

#define FPS_CALCULATOR_ENFORCE_THREAD_SAFETY 1

static const CGFloat DBFPSCalculatorTargetFramerate = 60.0;

@interface DTXFPSCalculator ()
{
	atomic_bool _enabled;
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	atomic_ulong _frameCount;
#else
	uint64_t _frameCount;
#endif

#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	atomic_double _lastKnownFPS;
#else
	double _lastKnownFPS;
#endif
}

@property (nonatomic, strong) CADisplayLink *displayLink;

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

- (void)stop
{
	[self.displayLink setPaused:YES];
	[self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - FPS Monitoring

- (void)setupFPSMonitoring
{
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
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
		atomic_store(&_lastKnownFPS, 0);
#else
		_lastKnownFPS = 0;
#endif
		
		return;
	}
	
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	uint64_t frameCount = atomic_exchange(&_frameCount, 0);
#else
	uint64_t frameCount = _frameCount;
	_frameCount = 0;
#endif
	double fps = MIN(frameCount / interval, DBFPSCalculatorTargetFramerate);
	
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	atomic_store(&_lastKnownFPS, fps);
#else
	_lastKnownFPS = fps;
#endif
	
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
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	atomic_exchange(&_frameCount, 0);
#else
	_frameCount = 0;
#endif
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
	double fps;
	
#if FPS_CALCULATOR_ENFORCE_THREAD_SAFETY
	fps = atomic_load(&_lastKnownFPS);
#else
	fps = _lastKnownFPS;
#endif
	
	return fps;
}

@end
