//
//  DTXProfilingConfiguration.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Profiling configuration object for the Profiler.
 */
@interface DTXProfilingConfiguration : NSObject

/**
 *  Returns a newly created default profiling configuration object.
 */
+ (instancetype)defaultProfilingConfiguration;

/**
 *  Returns a newly created default profiling configuration object fore remote profiling.
 */
+ (instancetype)defaultProfilingConfigurationForRemoteProfiling;

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
 *  The default value is @c 200.
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
 *  Collect stack trace information where appropriate.
 *
 *  Collecting stack traces may introduce some performance hit.
 *
 *  Stack trace collection is implemented using signals. Specifically, @c SIGPROF and @c SIGCHLD are used.
 *  If your application uses those signals or installs custom handlers for those signals, there may be collision issues.
 *
 *  The default value is @c false.
 */
@property (nonatomic) BOOL collectStackTraces;

/**
 *  Symbolicate stack traces at runtime.
 *
 *  Symbolicating stack traces may introduce some performance hit.
 *
 *  The default value is @c false.
 */
@property (nonatomic) BOOL symbolicateStackTraces;

/**
 *  Record log output during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic) BOOL recordLogOutput;

/**
 *  Profile React Native application.
 *
 *  Currently, only one active React Native bridge is supported.
 *  If you have different needs, open an issue at @ref https://github.com/wix/DetoxInstruments/issues
 *
 *  The default value is @c true.
 */
@property (nonatomic) BOOL profileReactNative;

/**
 *  Collect JavaScript stack trace information where appropriate.
 *
 *  Collecting JavaScript stack traces may introduce some performance hit.
 *
 *  JavaScript stack trace collection is implemented using signals. Specifically, @c SIGPROF and @c SIGCHLD are used.
 *  If your application uses those signals or installs custom handlers for those signals, there may be collision issues.
 *
 *  The default value is @c false.
 */
@property (nonatomic) BOOL collectJavaScriptStackTraces;

/**
 *  Symbolicate JavaScript stack traces at runtime using source maps (if available).
 *
 *  Symbolicating JavaScript stack traces may introduce some performance hit.
 *
 *  The default value is @c false.
 */
@property (nonatomic) BOOL symbolicateJavaScriptStackTraces;

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

@end

NS_ASSUME_NONNULL_END
