//
//  DTXProfilerAPI-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/18/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#ifndef DTXProfilerAPI_Private_h
#define DTXProfilerAPI_Private_h

#import "DTXProfilerAPI.h"
#import "DTXProfiler-Private.h"

extern NSString* const __DTXDidAddActiveProfilerNotification;
extern NSString* const __DTXDidRemoveActiveProfilerNotification;

extern pthread_mutex_t __active_profilers_mutex;
extern NSMutableSet<DTXProfiler*>* __activeProfilers;

extern void __DTXProfilerActiveProfilersInit(void);

static
DTX_ALWAYS_INLINE
inline DTXProfilingConfiguration* __DTXProfilerGetActiveConfiguration(void)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	auto rv = __activeProfilers.anyObject.profilingConfiguration.copy;
	
	pthread_mutex_unlock(&__active_profilers_mutex);
	
	return rv;
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerAddActiveProfiler(DTXProfiler* profiler)
{
	__DTXProfilerActiveProfilersInit();
	
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers addObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(), CF(__DTXDidAddActiveProfilerNotification), CF(profiler), nil, YES);
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerRemoveActiveProfiler(DTXProfiler* profiler)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers removeObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(), CF(__DTXDidRemoveActiveProfilerNotification), CF(profiler), nil, YES);
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerEnumerateActiveProfilersWithBlock(void (^block)(DTXProfiler* profiler))
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	for (DTXProfiler* profiler in __activeProfilers)
	{
		block(profiler);
	}
	
	pthread_mutex_unlock(&__active_profilers_mutex);
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerAddTag(NSDate* timestamp, NSString* tag)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addTag:tag timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerAddLogLine(NSDate* timestamp, NSString* line)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogLine:line timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerAddLogLineWithObjects(NSDate* timestamp, NSString* line, NSArray* objects)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogLine:line objects:objects timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEventIntervalBeginIdentifier(NSString* identifier, NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo, BOOL isTimer, BOOL isRNNativeEvent , NSArray* stackTrace)
{
	uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalBeginWithIdentifier:identifier category:category name:name additionalInfo:additionalInfo isTimer:isTimer isRNNativeEvent:isRNNativeEvent stackTrace:stackTrace threadIdentifier:threadIdentifier timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
inline NSString* __DTXProfilerMarkEventIntervalBegin(NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo, BOOL isTimer, BOOL isRNNativeEvent, NSArray* stackTrace)
{
	NSString* rv = NSUUID.UUID.UUIDString;
	
	__DTXProfilerMarkEventIntervalBeginIdentifier(rv, timestamp, category, name, additionalInfo, isTimer, isRNNativeEvent, stackTrace);
	
	return rv;
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEventIntervalEnd(NSDate* timestamp, NSString* identifier, DTXEventStatus eventStatus, NSString* additionalInfo)
{
	uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
	
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalEndWithIdentifier:identifier eventStatus:eventStatus additionalInfo:additionalInfo threadIdentifier:threadIdentifier timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEventIdentifier(NSString* identifier, NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo)
{
	uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
	
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventWithIdentifier:identifier category:category name:name eventStatus:eventStatus additionalInfo:additionInfo threadIdentifier:threadIdentifier timestamp:timestamp];
	});
}


static
DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkEvent(NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo)
{
	NSString* rv = NSUUID.UUID.UUIDString;
	
	__DTXProfilerMarkEventIdentifier(rv, timestamp, category, name, eventStatus, additionInfo);
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkNetworkRequestBegin(NSURLRequest* request, NSString* uniqueIdentifier, NSDate* timestamp)
{
	//Make sure to take a copy so it is not modified while processing.
	request = request.copy;
	id cookies = request.HTTPShouldHandleCookies ? [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:request.URL] : nil;
	NSDictionary<NSString*, NSString*>* cookieHeaders = nil;
	if(cookies)
	{
		cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
	}
	
	NSString* userAgent = [DTXNetworkRecorder cfNetworkUserAgent];
	
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _networkRecorderDidStartRequest:request cookieHeaders:cookieHeaders userAgent:userAgent uniqueIdentifier:uniqueIdentifier timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerMarkNetworkResponseEnd(NSURLResponse* response, NSData* data, NSError* error, NSString* uniqueIdentifier, NSDate* timestamp)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _networkRecorderDidFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
inline void __DTXProfilerAddRNBridgeDataCapture(NSString* functionName, NSArray<NSString*>* arguments, NSString* returnValue, NSString* exception, BOOL isFromNative)
{
	if(arguments.count == 0)
	{
		return;
	}
	
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addRNDataFromFunction:functionName arguments:arguments returnValue:returnValue exception:exception isFromNative:isFromNative timestamp:NSDate.date];
	});
}

#endif /* DTXProfilerAPI_Private_h */
