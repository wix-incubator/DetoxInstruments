//
//  DTXProfilerAPI-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/18/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
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
DTXProfilingConfiguration* __DTXProfilerGetActiveConfiguration(void)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	auto rv = __activeProfilers.anyObject.profilingConfiguration.copy;
	
	pthread_mutex_unlock(&__active_profilers_mutex);
	
	return rv;
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerAddActiveProfiler(DTXProfiler* profiler)
{
	__DTXProfilerActiveProfilersInit();
	
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers addObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(), CF(__DTXDidAddActiveProfilerNotification), CF(profiler), nil, YES);
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerRemoveActiveProfiler(DTXProfiler* profiler)
{
	pthread_mutex_lock(&__active_profilers_mutex);
	
	[__activeProfilers removeObject:profiler];
	
	pthread_mutex_unlock(&__active_profilers_mutex);
	
	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(), CF(__DTXDidRemoveActiveProfilerNotification), CF(profiler), nil, YES);
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerEnumerateActiveProfilersWithBlock(void (^block)(DTXProfiler* profiler))
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
void __DTXProfilerAddTag(NSDate* timestamp, NSString* tag)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addTag:tag timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerAddLogEntry(NSDate* timestamp, DTXProfilerLogLevel level, NSString* subsystem, NSString* category, NSString* message)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogEntry:message timestamp:timestamp subsystem:subsystem category:category level:level];
	});
}


static
DTX_ALWAYS_INLINE
void __DTXProfilerAddLegacyLogEntryWithObjects(NSDate* timestamp, NSString* line, NSArray* objects)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addLogLine:line objects:objects timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkEventIntervalBeginIdentifierThreadIdentifier(NSString* identifier, uint64_t threadIdentifier, NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo, _DTXEventType eventType, NSArray* stackTrace)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalBeginWithIdentifier:identifier category:category name:name additionalInfo:additionalInfo eventType:eventType stackTrace:stackTrace threadIdentifier:threadIdentifier timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkEventIntervalBeginIdentifier(NSString* identifier, NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo, _DTXEventType eventType, NSArray* stackTrace)
{
	uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
	__DTXProfilerMarkEventIntervalBeginIdentifierThreadIdentifier(identifier, threadIdentifier, timestamp, category, name, additionalInfo, eventType, stackTrace);
}

static
DTX_ALWAYS_INLINE
NSString* __DTXProfilerMarkEventIntervalBegin(NSDate* timestamp, NSString* category, NSString* name, NSString* additionalInfo, _DTXEventType eventType, NSArray* stackTrace)
{
	NSString* rv = NSUUID.UUID.UUIDString;
	
	__DTXProfilerMarkEventIntervalBeginIdentifier(rv, timestamp, category, name, additionalInfo, eventType, stackTrace);
	
	return rv;
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkEventIntervalEndThreadIdentifier(uint64_t threadIdentifier, NSDate* timestamp, NSString* identifier, DTXEventStatus eventStatus, NSString* additionalInfo)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventIntervalEndWithIdentifier:identifier eventStatus:eventStatus additionalInfo:additionalInfo threadIdentifier:threadIdentifier timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkEventIntervalEnd(NSDate* timestamp, NSString* identifier, DTXEventStatus eventStatus, NSString* additionalInfo)
{
	uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
	
	__DTXProfilerMarkEventIntervalEndThreadIdentifier(threadIdentifier, timestamp, identifier, eventStatus, additionalInfo);
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkEventIdentifierThreadIdentifier(NSString* identifier, uint64_t threadIdentifier, NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo, _DTXEventType eventType)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _markEventWithIdentifier:identifier category:category name:name eventStatus:eventStatus additionalInfo:additionInfo eventType:eventType threadIdentifier:threadIdentifier timestamp:timestamp];
	});
}


static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkEventIdentifier(NSString* identifier, NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo, _DTXEventType eventType)
{
	uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
	
	__DTXProfilerMarkEventIdentifierThreadIdentifier(identifier, threadIdentifier, timestamp, category, name, eventStatus, additionInfo, eventType);
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkEvent(NSDate* timestamp, NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* additionInfo, _DTXEventType eventType)
{
	NSString* rv = NSUUID.UUID.UUIDString;
	
	__DTXProfilerMarkEventIdentifier(rv, timestamp, category, name, eventStatus, additionInfo, eventType);
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerMarkNetworkRequestBegin(NSURLRequest* request, NSString* uniqueIdentifier, NSDate* timestamp)
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
void __DTXProfilerMarkNetworkResponseEnd(NSURLResponse* response, NSData* data, NSError* error, NSString* uniqueIdentifier, NSDate* timestamp)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _networkRecorderDidFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerAddRNBridgeDataCapture(NSString* functionName, NSArray<NSString*>* arguments, NSString* returnValue, NSString* exception, BOOL isFromNative)
{
	if(arguments.count == 0)
	{
		return;
	}
	
	NSDate* timestamp = NSDate.date;
	
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addRNDataFromFunction:functionName arguments:arguments returnValue:returnValue exception:exception isFromNative:isFromNative timestamp:timestamp];
	});
}

static
DTX_ALWAYS_INLINE
void __DTXProfilerAddRNAsyncStorageOperation(NSDate* timestamp, int64_t fetchCount, double fetchDuration, int64_t saveCount, double saveDuration, NSString* operation, BOOL isDataKeysOnly, NSArray* data, NSDictionary* error)
{
	__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
		[profiler _addRNAsyncStorageOperation:operation fetchCount:fetchCount fetchDuration:fetchDuration saveCount:saveCount saveDuration:saveDuration isDataKeysOnly:isDataKeysOnly data:data error:error timestamp:timestamp];
	});
}

#endif /* DTXProfilerAPI_Private_h */
