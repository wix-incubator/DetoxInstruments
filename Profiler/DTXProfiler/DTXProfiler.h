//
//  DTXProfiler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTXProfiler/DTXProfilingConfiguration.h>
#import <DTXProfiler/DTXEventStatus.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Profiler objects are used to record profiling sessions.
 *
 *  Profiling configuration is achieved through @c DTXProfilingConfiguration instances.
 */
@interface DTXProfiler : NSObject

+ (NSString*)version;

/**
 *  A Boolean value indicating whether there is currently a recording in progress.
 */
@property (atomic, assign, readonly, getter=isRecording) BOOL recording;

/**
 * The profiling configuration provided to @c startProfilingWithConfiguration:. Will be null before calling that method.
 */
@property (atomic, copy, readonly, nullable) DTXProfilingConfiguration* profilingConfiguration;

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

@end

/**
 *  Push a sample group.
 *
 *  Subsequent samples will be pushed into this group.
 *
 *  @param name The name of the sample group to push.
 */
void DTXProfilerPushSampleGroup(NSString* name);

/**
 *  Pop a sample group.
 *
 *  Subsequent samples will be pushed into the parent group.
 */
void DTXProfilerPopSampleGroup(void);

/**
 *  Adds a tag.
 *
 *  Tags are added chronologically.
 *
 *  @param tag The tag name to push.
 */
void DTXProfilerAddTag(NSString* tag);

/**
 *  Adds a log line.
 *
 *  The line may be a multiline string.
 *
 *  Log lines are added chronologically.
 *
 *  @param line The line to add.
 */
void DTXProfilerAddLogLine(NSString* line);

/**
 *  Adds a log line and an array of object.
 *
 *  The line may be a multiline string.
 *
 *  Log lines are added chronologically.
 *
 *  @param line The line to add.
 *  @param objects The objects to add.
 */
void DTXProfilerAddLogLineWithObjects(NSString* line, NSArray* __nullable objects);

NSString* DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* __nullable additionalInfo);
void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable additionalInfo);
void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable additionInfo);

NS_ASSUME_NONNULL_END
