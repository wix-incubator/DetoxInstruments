//
//  DTXActivityRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/17/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXActivityRecorder.h"
#import "DTXProfilerAPI-Private.h"

static NSUInteger __activeListeningProfilers;
static pthread_mutex_t __activeListeningProfilersMutex;

@interface DTXActivityRecorder () /* <DTXSyncManagerDelegate> */

@end

@implementation DTXActivityRecorder 

static void __DTXDidAddProfiler(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo)
{
//	DTXProfiler* profiler = NS(object);
//	if(profiler.profilingConfiguration.recordInternalReactNativeEvents == YES)
	
}

static void __DTXDidRemoveProfiler(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo)
{
//	DTXProfiler* profiler = NS(object);
//	if(profiler.profilingConfiguration.recordInternalReactNativeEvents == YES)
	
}

+ (void)load
{
	__activeListeningProfilers = 0;
	pthread_mutex_init(&__activeListeningProfilersMutex, NULL);
	
	Class cls = NSClassFromString(@"DTXSyncManager");
	if(cls == nil)
	{
		NSURL* profilerURL = [NSBundle bundleForClass:DTXActivityRecorder.class].bundleURL;
		NSURL* detoxSyncURL = [profilerURL URLByAppendingPathComponent:@"Frameworks/DetoxSync.framework"];
		NSBundle* bundle = [[NSBundle alloc] initWithURL:detoxSyncURL];
		if([bundle load] == NO)
		{
			return;
		}
	}
	
	[NSClassFromString(@"DTXSyncManager") performSelector:@selector(setDelegate:) withObject:self];
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, __DTXDidAddProfiler, CF(__DTXDidAddActiveProfilerNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, __DTXDidRemoveProfiler, CF(__DTXDidRemoveActiveProfilerNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	
	//Iterate existing profilers and call the notification callback for them.
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		__DTXDidAddProfiler(nil, nil, CF(__DTXDidAddActiveProfilerNotification), CF(profiler), nil);
	});
}

+ (void)syncSystemDidStartTrackingEventWithIdentifier:(NSString*)identifier description:(NSString*)description
{
	__DTXProfilerMarkEventIntervalBeginIdentifier(identifier, NSDate.date, @"Activity", description, nil, NO, NO, YES, nil);
}

+ (void)syncSystemDidEndTrackingEventWithIdentifier:(NSString*)identifier description:(NSString*)description
{
	__DTXProfilerMarkEventIntervalEnd(NSDate.date, identifier, DTXEventStatusCompleted, nil);
}

@end
