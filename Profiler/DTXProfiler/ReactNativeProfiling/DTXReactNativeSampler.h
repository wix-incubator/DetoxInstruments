//
//  DTXReactNativeSampler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPollable.h"
#import "DTXProfiler.h"

@interface DTXReactNativeSampler : NSObject <DTXPollable>

+ (BOOL)isReactNativeInstalled;

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration;

@property (nonatomic, readonly) uint64_t bridgeNToJSCallCount;
@property (nonatomic, readonly) uint64_t bridgeNToJSCallCountDelta;

@property (nonatomic, readonly) uint64_t bridgeJSToNCallCount;
@property (nonatomic, readonly) uint64_t bridgeJSToNCallCountDelta;

@property (nonatomic, readonly) uint64_t bridgeNToJSDataSize;
@property (nonatomic, readonly) uint64_t bridgeNToJSDataSizeDelta;

@property (nonatomic, readonly) uint64_t bridgeJSToNDataSize;
@property (nonatomic, readonly) uint64_t bridgeJSToNDataSizeDelta;

@property (nonatomic, readonly) double cpu;

@property (nonatomic, strong /*not copy for performance - the string is well contained*/, readonly) NSString* currentStackTrace;
@property (nonatomic, readonly) BOOL currentStackTraceSymbolicated;

@end
