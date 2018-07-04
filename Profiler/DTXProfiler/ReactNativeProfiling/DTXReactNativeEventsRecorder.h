//
//  DTXReactNativeEventsRecorder.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 6/27/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTXProfiler/DTXEventStatus.h>

@protocol DTXReactNativeEventsListener <NSObject>

- (NSString*)markEventIntervalBeginWithCategory:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo;
- (void)markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo;
- (void)markEventWithCategory:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo;

@end

@interface DTXReactNativeEventsRecorder : NSObject

+ (BOOL)hasReactNativeEventsListeners;
+ (void)addReactNativeEventsListener:(id<DTXReactNativeEventsListener>)listener;
+ (void)removeReactNativeEventsListener:(id<DTXReactNativeEventsListener>)listener;

+ (id)markEventIntervalBeginWithCategory:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo;
+ (void)markEventIntervalEndWithIdentifiersData:(id)identifiersData eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo;
+ (void)markEventWithCategory:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo;

@end
