//
//  DTXProfiler-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXProfilingBasics.h"
#import <DTXProfiler/DTXProfiler.h>
#import <pthread.h>
#import "DTXPerformanceSampler.h"
#import "DTXNetworkRecorder.h"
//#import "DTXProfilerAPI-Private.h"

@interface DTXProfiler ()

@property (nonatomic, weak, getter=_profilerStoryListener, setter=_setInternalDelegate:) id<DTXProfilerStoryListener> _profilerStoryListener;

- (void)_symbolicatePerformanceSample:(DTXPerformanceSample*)sample;
- (void)_symbolicateRNPerformanceSample:(DTXReactNativePeroformanceSample*)sample;

- (DTXThreadInfo*)_threadForThreadIdentifier:(uint64_t)identifier;

//Private methods called from external API per active profiler.

- (void)_addTag:(NSString*)tag timestamp:(NSDate*)timestamp;
- (void)_addLogLine:(NSString*)line timestamp:(NSDate*)timestamp;
- (void)_addLogLine:(NSString *)line objects:(NSArray *)objects timestamp:(NSDate*)timestamp;
- (void)_markEventIntervalBeginWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo isTimer:(BOOL)isTimer isRNNativeEvent:(BOOL)isRNNativeEvent isActivity:(BOOL)isActivity stackTrace:(NSArray*)stackTrace threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp;
- (void)_markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp;
- (void)_markEventWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidStartRequest:(NSURLRequest*)request cookieHeaders:(NSDictionary<NSString*, NSString*>*)cookieHeaders userAgent:(NSString*)userAgent uniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;
- (void)_networkRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp;
- (void)_addRNDataFromFunction:(NSString*)function arguments:(NSArray<NSString*>*)arguments returnValue:(NSString*)rv exception:(NSString*)exception isFromNative:(BOOL)isFromNative timestamp:(NSDate*)timestamp;

@end
