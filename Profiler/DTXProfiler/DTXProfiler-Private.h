//
//  DTXProfiler-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteProfilingBasics.h"
#import "DTXProfiler.h"
#import <pthread.h>

extern pthread_mutex_t __active_profilers_mutex;
extern NSMutableSet<DTXProfiler*>* __activeProfilers;

@interface DTXProfiler ()

@property (nonatomic, weak, getter=_profilerStoryListener, setter=_setInternalDelegate:) id<DTXProfilerStoryListener> _profilerStoryListener;

- (void)_symbolicatePerformanceSample:(DTXAdvancedPerformanceSample*)sample;
- (void)_symbolicateRNPerformanceSample:(DTXReactNativePeroformanceSample*)sample;

//Private methods called from external API per active profiler.

- (void)_pushSampleGroupWithName:(NSString*)name timestamp:(NSDate*)timestamp;
- (void)_popSampleGroupWithTimestamp:(NSDate*)timestamp;
- (void)_addTag:(NSString*)tag timestamp:(NSDate*)timestamp;
- (void)_addLogLine:(NSString*)line timestamp:(NSDate*)timestamp;
- (void)_addLogLine:(NSString *)line objects:(NSArray *)objects timestamp:(NSDate*)timestamp;
- (void)_markEventIntervalBeginWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo timestamp:(NSDate*)timestamp;
- (void)_markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo timestamp:(NSDate*)timestamp;
- (void)_markEventWithCategory:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;

@end

__attribute__((always_inline))
inline void __DTXProfilerAddActiveProfiler(DTXProfiler* profiler)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers addObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
}

__attribute__((always_inline))
inline void __DTXProfilerRemoveActiveProfiler(DTXProfiler* profiler)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers removeObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
}

__attribute__((always_inline))
inline void __DTXProfilerEnumerateWithBlock(void (^block)(DTXProfiler* profiler))
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	for (DTXProfiler* profiler in __activeProfilers)
	{
		block(profiler);
	}
	
	pthread_mutex_unlock(&__active_profilers_mutex);
}

__attribute__((always_inline))
inline void __DTXProfilerPushSampleGroup(NSDate* timestamp, NSString* name)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _pushSampleGroupWithName:name timestamp:timestamp];
	});
}

__attribute__((always_inline))
inline void __DTXProfilerPopSampleGroup(NSDate* timestamp)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _popSampleGroupWithTimestamp:timestamp];
	});
}

__attribute__((always_inline))
inline void __DTXProfilerAddTag(NSDate* timestamp, NSString* tag)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _addTag:tag timestamp:timestamp];
	});
}

__attribute__((always_inline))
inline void __DTXProfilerAddLogLine(NSDate* timestamp, NSString* line)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogLine:line timestamp:timestamp];
	});
}

__attribute__((always_inline))
inline void __DTXProfilerAddLogLineWithObjects(NSDate* timestamp, NSString* line, NSArray* objects)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogLine:line objects:objects timestamp:timestamp];
	});
}

__attribute__((always_inline))
inline NSString* __DTXProfilerMarkEventIntervalBegin(NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo)
{
	NSString* rv = NSUUID.UUID.UUIDString;
	
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalBeginWithIdentifier:rv category:category name:name additionalInfo:additionalInfo timestamp:timestamp];
	});
	
	return rv;
}

__attribute__((always_inline))
inline void __DTXProfilerMarkEventIntervalEnd(NSDate* timestamp, NSString* identifier, DTXEventStatus eventStatus, NSString* additionalInfo)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalEndWithIdentifier:identifier eventStatus:eventStatus additionalInfo:additionalInfo timestamp:timestamp];
	});
}

__attribute__((always_inline))
inline void __DTXProfilerMarkEvent(NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventWithCategory:category name:name eventStatus:eventStatus additionalInfo:additionInfo timestamp:timestamp];
	});
}

__attribute__((always_inline))
inline void __DTXProfilerMarkNetworkRequestBegin(NSURLRequest* request, NSString* uniqueIdentifier, NSDate* timestamp)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _networkRecorderDidStartRequest:request uniqueIdentifier:uniqueIdentifier timestamp:timestamp];
	});
}

__attribute__((always_inline))
inline void __DTXProfilerMarkNetworkResponseEnd(NSURLResponse* response, NSData* data, NSError* error, NSString* uniqueIdentifier, NSDate* timestamp)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _networkRecorderDidFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier timestamp:timestamp];
	});
}
