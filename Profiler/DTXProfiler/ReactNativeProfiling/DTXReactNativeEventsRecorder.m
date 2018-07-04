//
//  DTXReactNativeEventsRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 6/27/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXReactNativeEventsRecorder.h"
#import <pthread.h>

static NSMutableArray<id<DTXReactNativeEventsListener>>* __reactNativeEventListeners;
static NSMutableDictionary<NSString*, id<DTXReactNativeEventsListener>>* __reactNativeEventListenerMapping;
static pthread_mutex_t __reactNativeEventListenersMutex;

@implementation DTXReactNativeEventsRecorder

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__reactNativeEventListeners = [NSMutableArray new];
		__reactNativeEventListenerMapping = [NSMutableDictionary new];
		pthread_mutex_init(&__reactNativeEventListenersMutex, NULL);
	});
}

+ (BOOL)hasReactNativeEventsListeners
{
	BOOL rv = NO;
	pthread_mutex_lock(&__reactNativeEventListenersMutex);
	rv = __reactNativeEventListeners.count > 0;
	pthread_mutex_unlock(&__reactNativeEventListenersMutex);
	
	return rv;
}

+ (void)addReactNativeEventsListener:(id<DTXReactNativeEventsListener>)listener
{
	pthread_mutex_lock(&__reactNativeEventListenersMutex);
	[__reactNativeEventListeners addObject:listener];
	__reactNativeEventListenerMapping[[NSString stringWithFormat:@"%p", listener]] = listener;
	pthread_mutex_unlock(&__reactNativeEventListenersMutex);
}

+ (void)removeReactNativeEventsListener:(id<DTXReactNativeEventsListener>)listener
{
	pthread_mutex_lock(&__reactNativeEventListenersMutex);
	[__reactNativeEventListeners removeObject:listener];
	[__reactNativeEventListenerMapping removeObjectForKey:[NSString stringWithFormat:@"%p", listener]];
	pthread_mutex_unlock(&__reactNativeEventListenersMutex);
}

+ (id)markEventIntervalBeginWithCategory:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo;
{
	NSMutableDictionary<NSString*, NSString*>* rv = [NSMutableDictionary new];
	
	pthread_mutex_lock(&__reactNativeEventListenersMutex);
	[__reactNativeEventListeners enumerateObjectsUsingBlock:^(id<DTXReactNativeEventsListener>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* identifier = [obj markEventIntervalBeginWithCategory:category name:name additionalInfo:additionalInfo];
		rv[[NSString stringWithFormat:@"%p", obj]] = identifier;
	}];
	pthread_mutex_unlock(&__reactNativeEventListenersMutex);
	
	return rv;
}

+ (void)markEventIntervalEndWithIdentifiersData:(NSDictionary<NSString*, NSString*>*)identifiersData eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo;
{
	if(identifiersData.count == 0)
	{
		return;
	}
	
	pthread_mutex_lock(&__reactNativeEventListenersMutex);
	[identifiersData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull identifier, BOOL * _Nonnull stop) {
		[__reactNativeEventListenerMapping[key] markEventIntervalEndWithIdentifier:identifier eventStatus:eventStatus additionalInfo:additionalInfo];
	}];
	pthread_mutex_unlock(&__reactNativeEventListenersMutex);
}

+ (void)markEventWithCategory:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo;
{
	pthread_mutex_lock(&__reactNativeEventListenersMutex);
	[__reactNativeEventListeners enumerateObjectsUsingBlock:^(id<DTXReactNativeEventsListener>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj markEventWithCategory:category name:name eventStatus:eventStatus additionalInfo:additionalInfo];
	}];
	pthread_mutex_unlock(&__reactNativeEventListenersMutex);
}


@end
