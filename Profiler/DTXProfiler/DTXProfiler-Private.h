//
//  DTXProfiler-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfilingBasics.h"
#import <DTXProfiler/DTXProfiler.h>
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
- (void)_markEventIntervalBeginWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo isTimer:(BOOL)isTimer stackTrace:(NSArray*)stackTrace timestamp:(NSDate*)timestamp;
- (void)_markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo timestamp:(NSDate*)timestamp;
- (void)_markEventWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;
- (void)_addRNDataFromFunction:(NSString*)function arguments:(NSArray<NSString*>*)arguments returnValue:(NSString*)rv exception:(NSString*)exception isFromNative:(BOOL)isFromNative timestamp:(NSDate*)timestamp;

@end

DTX_ALWAYS_INLINE
inline DTXProfilingConfiguration* __DTXProfilerGetActiveConfiguration(void)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	auto rv = __activeProfilers.anyObject.profilingConfiguration.copy;
	
	pthread_mutex_unlock(&__active_profilers_mutex);
	
	return rv;
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerAddActiveProfiler(DTXProfiler* profiler)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers addObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerRemoveActiveProfiler(DTXProfiler* profiler)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers removeObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerEnumerateWithBlock(void (^block)(DTXProfiler* profiler))
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	for (DTXProfiler* profiler in __activeProfilers)
	{
		block(profiler);
	}
	
	pthread_mutex_unlock(&__active_profilers_mutex);
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerPushSampleGroup(NSDate* timestamp, NSString* name)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _pushSampleGroupWithName:name timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerPopSampleGroup(NSDate* timestamp)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _popSampleGroupWithTimestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerAddTag(NSDate* timestamp, NSString* tag)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _addTag:tag timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerAddLogLine(NSDate* timestamp, NSString* line)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogLine:line timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerAddLogLineWithObjects(NSDate* timestamp, NSString* line, NSArray* objects)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogLine:line objects:objects timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEventIntervalBeginIdentifier(NSString* identifier, NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo, BOOL isTimer, NSArray* stackTrace)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalBeginWithIdentifier:identifier category:category name:name additionalInfo:additionalInfo isTimer:isTimer stackTrace:stackTrace timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline NSString* __DTXProfilerMarkEventIntervalBegin(NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo, BOOL isTimer, NSArray* stackTrace)
{
	NSString* rv = NSUUID.UUID.UUIDString;
	
	__DTXProfilerMarkEventIntervalBeginIdentifier(rv, timestamp, category, name, additionalInfo, isTimer, stackTrace);
	
	return rv;
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEventIntervalEnd(NSDate* timestamp, NSString* identifier, DTXEventStatus eventStatus, NSString* additionalInfo)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalEndWithIdentifier:identifier eventStatus:eventStatus additionalInfo:additionalInfo timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEventIdentifier(NSString* identifier, NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventWithIdentifier:identifier category:category name:name eventStatus:eventStatus additionalInfo:additionInfo timestamp:timestamp];
	});
}


DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEvent(NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo)
{
	NSString* rv = NSUUID.UUID.UUIDString;
	
	__DTXProfilerMarkEventIdentifier(rv, timestamp, category, name, eventStatus, additionInfo);
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkNetworkRequestBegin(NSURLRequest* request, NSString* uniqueIdentifier, NSDate* timestamp)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _networkRecorderDidStartRequest:request uniqueIdentifier:uniqueIdentifier timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkNetworkResponseEnd(NSURLResponse* response, NSData* data, NSError* error, NSString* uniqueIdentifier, NSDate* timestamp)
{
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _networkRecorderDidFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier timestamp:timestamp];
	});
}

DTX_ALWAYS_INLINE
inline void __DTXProfilerAddRNBridgeDataCapture(NSString* functionName, NSArray<NSString*>* arguments, NSString* returnValue, NSString* exception, BOOL isFromNative)
{
	if(arguments.count == 0)
	{
		return;
	}
	
	__DTXProfilerEnumerateWithBlock(^(DTXProfiler *profiler) {
		[profiler _addRNDataFromFunction:functionName arguments:arguments returnValue:returnValue exception:exception isFromNative:isFromNative timestamp:NSDate.date];
	});
}
