//
//  DTXProfiler-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXProfilingBasics.h"
#import <DTXProfiler/DTXProfiler.h>
#import <pthread.h>
#import "DTXPerformanceSampler.h"
#import "DTXNetworkRecorder.h"
#import "DTXInstruments+CoreDataModel.h"
//#import "DTXProfilerAPI-Private.h"

typedef NS_ENUM(NSUInteger, _DTXEventType)
{
	_DTXEventTypeSignpost,
	_DTXEventTypeActivity,
	_DTXEventTypeDetoxLifecycle,
	_DTXEventTypeJSTimer,
	_DTXEventTypeInternalRN
};

DTX_ALWAYS_INLINE
static Class _DTXClassForEventType(_DTXEventType eventType)
{
	switch (eventType) {
		case _DTXEventTypeSignpost:
			return DTXSignpostSample.class;
		case _DTXEventTypeActivity:
			return DTXActivitySample.class;
		case _DTXEventTypeDetoxLifecycle:
			return DTXDetoxLifecycleSample.class;
		case _DTXEventTypeJSTimer:
			return DTXActivitySample.class;
		case _DTXEventTypeInternalRN:
			return DTXActivitySample.class;
	}
}

DTX_ALWAYS_INLINE
static BOOL _DTXShouldIgnoreEvent(_DTXEventType eventType, NSString* category, DTXProfilingConfiguration* config)
{
	if(eventType == _DTXEventTypeJSTimer && config.recordReactNativeTimersAsActivity == NO)
	{
		return YES;
	}
	
	if(eventType == _DTXEventTypeInternalRN && config.recordInternalReactNativeActivity == NO)
	{
		return NO;
	}
	
	Class targetClass = _DTXClassForEventType(eventType);
	
	if(targetClass == DTXSignpostSample.class && config.recordEvents == NO)
	{
		return YES;
	}
	
	if(targetClass == DTXSignpostSample.class && [config.ignoredEventCategories containsObject:category])
	{
		return YES;
	}
	
	if(targetClass == DTXActivitySample.class && config.recordActivity == NO)
	{
		return YES;
	}
	
	return NO;
}

@interface DTXProfiler ()

@property (nonatomic, weak, getter=_profilerStoryListener, setter=_setInternalDelegate:) id<DTXProfilerStoryListener> _profilerStoryListener;

@property (nonatomic) BOOL _cleanForDemo;

- (void)_symbolicatePerformanceSample:(DTXPerformanceSample*)sample;
- (void)_symbolicateRNPerformanceSample:(DTXReactNativePerformanceSample*)sample;

- (DTXThreadInfo*)_threadForThreadIdentifier:(uint64_t)identifier;

//Private methods called from external API per active profiler.

- (void)_addTag:(NSString*)tag timestamp:(NSDate*)timestamp;
- (void)_addLogLine:(NSString*)line timestamp:(NSDate*)timestamp;
- (void)_addLogLine:(NSString *)line objects:(NSArray *)objects timestamp:(NSDate*)timestamp;
- (void)_markEventIntervalBeginWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo eventType:(_DTXEventType)eventType stackTrace:(NSArray*)stackTrace threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp;
- (void)_markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp;
- (void)_markEventWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo eventType:(_DTXEventType)eventType threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidStartRequest:(NSURLRequest*)request cookieHeaders:(NSDictionary<NSString*, NSString*>*)cookieHeaders userAgent:(NSString*)userAgent uniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;
- (void)_addRNDataFromFunction:(NSString*)function arguments:(NSArray<NSString*>*)arguments returnValue:(NSString*)rv exception:(NSString*)exception isFromNative:(BOOL)isFromNative timestamp:(NSDate*)timestamp;
- (void)_addRNAsyncStorageOperation:(NSString*)operation fetchCount:(int64_t)fetchCount fetchDuration:(double)fetchDuration saveCount:(int64_t)saveCount saveDuration:(double)saveDuration isDataKeysOnly:(BOOL)isDataKeysOnly data:(NSArray*)data error:(NSDictionary*)error timestamp:(NSDate*)timestamp;

@end
