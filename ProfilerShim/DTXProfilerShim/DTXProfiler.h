//
//  DTXProfiler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

@import Foundation;
#import "DTXBase.h"
#import "DTXProfilingConfiguration.h"
#import "DTXEvents.h"
#import "DTXProfilerAPI.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Profiler objects are used to record profiling sessions.
 *
 *  Profiling configuration is achieved through @c DTXProfilingConfiguration instances.
 */
@interface DTXProfiler : NSObject

/**
 *  The version string of the Profiler framework.
 */
@property (class, nonatomic, readonly, copy) NSString* version;

/**
 *  A Boolean value indicating whether there is currently a recording in progress.
 */
@property (atomic, assign, readonly, getter=isRecording) BOOL recording;

/**
 *  The profiling configuration provided to @c startProfilingWithConfiguration:. Will be null before calling that method.
 */
@property (atomic, copy, readonly, nullable) DTXProfilingConfiguration* profilingConfiguration;

/**
 *  Starts a profiling recording with the provided configuration.
 *
 *  @param configuration The configuration to use for profiling.
 */
- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;

/**
 *  Continues an existing profiling recording with the provided configuration, or if one does not exist, starts a new profiling recording.
 *  If a recording is continued, the previous configuration is used.
 *
 *  @param configuration The configuration to use for profiling.
 */
- (void)continueProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;

/**
 *  Stops the profiling recording.
 *
 *  If a completion handler is provided, it is called after the recording is saved to disk.
 *  In most cases, this is called soon after calling @c stopProfilingWithCompletionHandler:,
 *  however there may be cases when the stop operation may take a while to complete.
 *
 *  The completion handler is called on a background queue.
 *
 *  @param completionHandler Completion handler called after the recording is saved to disk.
 */
- (void)stopProfilingWithCompletionHandler:(void(^ __nullable)(NSError* __nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
