//
//  DTXPerformanceSampler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPollable.h"
#import "DTXProfiler.h"

@import Darwin;

@interface DTXThreadMeasurement : NSObject

@property (nonatomic) thread_t machThread;
@property (nonatomic) uint64_t identifier;
@property (nonatomic, strong) NSString* name;
@property (nonatomic) double cpu;

@end

@interface DTXCPUMeasurement : NSObject

@property (nonatomic) double totalCPU;
@property (nonatomic) NSUInteger heaviestThreadIdx;
@property (nonatomic) NSArray<DTXThreadMeasurement*>* threads;
@property (nonatomic) DTXThreadMeasurement* heaviestThread;

@end

@interface DTXPerformanceSampler : NSObject <DTXPollable>

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration;

@property (nonatomic, strong, readonly) DTXCPUMeasurement* currentCPU;
@property (nonatomic, readonly) uint64_t currentMemory;
@property (nonatomic, readonly) double currentFPS;
@property (nonatomic, readonly) uint64_t currentDiskReads;
@property (nonatomic, readonly) uint64_t currentDiskReadsDelta;
@property (nonatomic, readonly) uint64_t currentDiskWrites;
@property (nonatomic, readonly) uint64_t currentDiskWritesDelta;
@property (nonatomic, readonly) NSArray<NSString*>* currentOpenFiles;

@property (nonatomic, strong, readonly) NSArray<NSNumber*>* callStackSymbols;

@end
