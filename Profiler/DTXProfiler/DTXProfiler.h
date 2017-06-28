//
//  DTXProfiler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Profiling configuration object for the Profiler.
 */
@interface DTXProfilingConfiguration : NSObject <NSSecureCoding>

// Sampling Configuration

/**
 *  The sampling interval of the Profiler.
 *
 *  The default value is 0.5.
 */
@property (nonatomic) NSTimeInterval samplingInterval;

/**
 *  The minimum number of samples to keep in memory before flushing to disk.
 *
 *  Larger number of samples in memory will improve performance at the cost of memory use.
 *
 *  The default value is 200.
 */
@property (nonatomic) NSUInteger numberOfSamplesBeforeFlushToDisk;

//Recording Configuration

/**
 *  Record network requests during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic) BOOL recordNetwork;

/**
 *  Record localhost network requests during profiling.
 *
 *  Only relevant if @c recordNetwork is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic) BOOL recordLocalhostNetwork;

/**
 *  Record thread information during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic) BOOL recordThreadInformation;

/**
 *  Record log output during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic) BOOL recordLogOutput;

/* Output Configuration */

/**
 *  Prints the JSON portion of the output in a pretty manner.
 *
 *  The default value is @c false.
 */
@property (nonatomic) BOOL prettyPrintJSONOutput;

/**
 *  The recording file URL to save to.
 *
 *  If this URL is a directory URL, a new recording will be created in that directory with the date and time of the recording.
 *
 *  If the URL is a file URL, a new recording will be created with that name.
 *
 *  The extension of the recording package is always @c .dtxprof.
 *
 *  If set to @c nil, the value will reset to the default value.
 *
 *  The default value is a file name with the date and time of the recording, in the documents folder of the device.
 */
@property (nonatomic, copy, null_resettable) NSURL* recordingFileURL;

/**
 *  Returns a newly created default profiling configuration object.
 */
+ (instancetype)defaultProfilingConfiguration;

@end

/**
 *  Profiler objects are used to record profiling sessions.
 *
 *  Profiling configuration is achieved through @c DTXProfilingConfiguration instances.
 */
@interface DTXProfiler : NSObject

/**
 *  A Boolean value indicating whether there is currently a recording in progress.
 */
@property (atomic, assign, readonly, getter=isRecording) BOOL recording;

/**
 *  Starts a profiling recording with the provided configuration.
 *
 *  @param configuration The configuration to use for profiling.
 */
- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;

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

/**
 *  Push a sample group.
 *
 *  Subsequent samples will be pushed into this group.
 *
 *  @param name The name of the sample group to push.
 */
- (void)pushSampleGroupWithName:(NSString*)name;
/**
 *  Pop a sample group.
 *
 *  Subsequent samples will be pushed into the parent group.
 */
- (void)popSampleGroup;

/**
 *  Adds a tag.
 *
 *  Tags are added chronologically.
 *
 *  @param tag The tag name to push.
 */
- (void)addTag:(NSString*)tag;

/**
 *  Adds a log line.
 *
 *  The line may be a multiline string.
 *
 *  Log lines are added chronologically.
 *
 *  @param line The line to add.
 */
- (void)addLogLine:(NSString*)line;

@end

NS_ASSUME_NONNULL_END
