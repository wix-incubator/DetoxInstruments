//
//  DTXPerformanceSampler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPollable.h"
#import "DTXProfiler.h"
#import "DBPerformanceToolkit.h"

@interface DTXPerformanceSampler : NSObject <DTXPollable>

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration;

@property (nonatomic, strong, readonly) DBPerformanceToolkit* performanceToolkit;
@property (nonatomic, strong, readonly) NSArray<NSNumber*>* callStackSymbols;

@end
