//
//  DTXActivityRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/17/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXActivityRecorder.h"
#import "DTXProfilerAPI-Private.h"

static NSUInteger __activeListeningProfilers;
static pthread_mutex_t __activeListeningProfilersMutex;

@interface DTXActivityRecorder () /* <DTXSyncManagerDelegate> */

@end

@implementation DTXActivityRecorder

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
}

+ (void)syncSystemDidStartTrackingEventWithIdentifier:(NSString*)identifier description:(NSString*)description objectDescription:(NSString*)objectDescription additionalDescription:(nullable NSString*)additionalDescription
{
//	NSLog(@"🤦‍♂️ %@ %@ %@ %@", identifier, description, objectDescription, additionalDescription);
	__DTXProfilerMarkEventIntervalBeginIdentifier(identifier, NSDate.date, description, objectDescription, additionalDescription, NO, NO, /*activity:*/YES, nil);
}

+ (void)syncSystemDidEndTrackingEventWithIdentifier:(NSString*)identifier
{
	__DTXProfilerMarkEventIntervalEnd(NSDate.date, identifier, DTXEventStatusCompleted, nil);
}

@end
