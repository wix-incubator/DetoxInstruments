//
//  DTXProfilingConfiguration.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

@import Foundation;

@class DTXMutableProfilingConfiguration;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Profiling configuration object for the Profiler.
 */
@interface DTXProfilingConfiguration : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>

- (DTXProfilingConfiguration*)copy;
- (DTXMutableProfilingConfiguration*)mutableCopy;

/**
 *  A newly created default profiling configuration object.
 */
@property (class, nonatomic, strong, readonly) DTXProfilingConfiguration* defaultProfilingConfiguration;

/**
 *  A newly created default profiling configuration object fore remote profiling.
 */
@property (class, nonatomic, strong, readonly) DTXProfilingConfiguration* defaultProfilingConfigurationForRemoteProfiling;

#pragma mark Recording Configuration

/**
 *  The minimum number of samples to keep in memory before flushing to disk.
 *
 *  Larger number of samples in memory will improve performance at the cost of memory use.
 *
 *  The default value is @c 200.
 */
@property (nonatomic, readonly) NSUInteger numberOfSamplesBeforeFlushToDisk;

/**
 *  Record performance information during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readonly) BOOL recordPerformance;

/**
 *  The sampling interval of the Profiler.
 *
 *  The default value is 0.5.
 */
@property (nonatomic, readonly) NSTimeInterval samplingInterval;

/**
 *  Record thread information during profiling.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readonly) BOOL recordThreadInformation;

/**
 *  Collect stack trace information where appropriate.
 *
 *  Collecting stack traces may introduce some performance hit.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readonly) BOOL collectStackTraces;

/**
 *  Symbolicate stack traces at runtime.
 *
 *  Symbolicating stack traces may introduce some performance hit.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readonly) BOOL symbolicateStackTraces;

/**
 *  Collect the names of open files for each sample.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readonly) BOOL collectOpenFileNames;

/**
 *  Record network requests during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readonly) BOOL recordNetwork;

/**
 *  Record localhost network requests during profiling.
 *
 *  Only relevant if @c recordNetwork is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readonly) BOOL recordLocalhostNetwork;

/**
 *  Disables cache for network requests.
 *
 *  Only relevant if @c recordNetwork is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readonly) BOOL disableNetworkCache;

/**
 *  Record events during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readonly) BOOL recordEvents;

/**
 *  A set of categories to ignore when profiling.
 *  Use this property to prevent clutter in the Events instrument.
 *
 *  Only relevant if @c recordEvents is set to @c true.
 *
 *  The default value is an empty set.
 */
@property (nonatomic, copy, null_resettable, readonly) NSSet<NSString*>* ignoredEventCategories;

/**
 *  Record log output during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readonly) BOOL recordLogOutput;

/**
 *  Profile React Native application.
 *
 *  Currently, only one active React Native bridge is supported.
 *  If you have different needs, open an issue at @ref https://github.com/wix/DetoxInstruments/issues
 *
 *  The default value is @c true.
 */
@property (nonatomic, readonly) BOOL profileReactNative;

/**
 *  Record React Native bridge data during profiling.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readonly) BOOL recordReactNativeBridgeData;

/**
 *  Record React Native timers (created using @c setTimeout() in JavaScript) as events.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readonly) BOOL recordReactNativeTimersAsEvents;

/**
 *  Record internal React Native events.
 *
 *  Taps into the internal profiling mechanisms to collect internal React Native profiling events.
 *
 *  The default value is @c false.
 */
@property(nonatomic, readonly) BOOL recordInternalReactNativeEvents;

/* Output Configuration */

/**
 *  The recording file URL to save to.
 *
 *  If this URL is a directory URL, a new recording will be created in that directory with the date and time of the recording.
 *
 *  If the URL is a file URL, a new recording will be created with that name.
 *
 *  The extension of the recording package is always @c .dtxrec.
 *
 *  If set to @c nil, the URL will reset to the default value.
 *
 *  The default value is a file name with the date and time of the recording, in the documents folder of the profiled app.
 */
@property (nonatomic, copy, null_resettable, readonly) NSURL* recordingFileURL;

@end

#pragma mark -

/**
 *  Profiling configuration object for the Profiler.
 */
@interface DTXMutableProfilingConfiguration : DTXProfilingConfiguration

/**
 *  A newly created default profiling configuration object.
 */
@property (class, nonatomic, strong, readonly) DTXMutableProfilingConfiguration* defaultProfilingConfiguration;

/**
 *  A newly created default profiling configuration object fore remote profiling.
 */
@property (class, nonatomic, strong, readonly) DTXMutableProfilingConfiguration* defaultProfilingConfigurationForRemoteProfiling;

#pragma mark Recording Configuration

/**
 *  The minimum number of samples to keep in memory before flushing to disk.
 *
 *  Larger number of samples in memory will improve performance at the cost of memory use.
 *
 *  The default value is @c 200.
 */
@property (nonatomic, readwrite) NSUInteger numberOfSamplesBeforeFlushToDisk;

/**
 *  Record performance information during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readwrite) BOOL recordPerformance;

/**
 *  The sampling interval of the Profiler.
 *
 *  The default value is 0.5.
 */
@property (nonatomic, readwrite) NSTimeInterval samplingInterval;

/**
 *  Record thread information during profiling.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readwrite) BOOL recordThreadInformation;

/**
 *  Collect stack trace information where appropriate.
 *
 *  Collecting stack traces may introduce some performance hit.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readwrite) BOOL collectStackTraces;

/**
 *  Symbolicate stack traces at runtime.
 *
 *  Symbolicating stack traces may introduce some performance hit.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readwrite) BOOL symbolicateStackTraces;

/**
 *  Collect the names of open files for each sample.
 *
 *  Only relevant if @c recordPerformance is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readwrite) BOOL collectOpenFileNames;

/**
 *  Record network requests during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readwrite) BOOL recordNetwork;

/**
 *  Record localhost network requests during profiling.
 *
 *  Only relevant if @c recordNetwork is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readwrite) BOOL recordLocalhostNetwork;

/**
 *  Disables cache for network requests.
 *
 *  Only relevant if @c recordNetwork is set to @c true.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readwrite) BOOL disableNetworkCache;

/**
 *  Record events during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readwrite) BOOL recordEvents;

/**
 *  A set of categories to ignore when profiling.
 *  Use this property to prevent clutter in the Events instrument.
 *
 *  Only relevant if @c recordEvents is set to @c true.
 *
 *  The default value is an empty set.
 */
@property (nonatomic, copy, null_resettable, readwrite) NSSet<NSString*>* ignoredEventCategories;

/**
 *  Record log output during profiling.
 *
 *  The default value is @c true.
 */
@property (nonatomic, readwrite) BOOL recordLogOutput;

/**
 *  Profile React Native application.
 *
 *  Currently, only one active React Native bridge is supported.
 *  If you have different needs, open an issue at @ref https://github.com/wix/DetoxInstruments/issues
 *
 *  The default value is @c true.
 */
@property (nonatomic, readwrite) BOOL profileReactNative;

/**
 *  Record React Native bridge data during profiling.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readwrite) BOOL recordReactNativeBridgeData;

/**
 *  Record React Native timers (created using @c setTimeout() in JavaScript) as events.
 *  Timers will appear as interval events in the Events instrument.
 *
 *  The default value is @c false.
 */
@property (nonatomic, readwrite) BOOL recordReactNativeTimersAsEvents;

/**
 *  Record internal React Native events.
 *
 *  Taps into the internal profiling mechanisms to collect internal React Native profiling events.
 *
 *  The default value is @c false.
 */
@property(nonatomic, readwrite) BOOL recordInternalReactNativeEvents;

/* Output Configuration */

/**
 *  The recording file URL to save to.
 *
 *  If this URL is a directory URL, a new recording will be created in that directory with the date and time of the recording.
 *
 *  If the URL is a file URL, a new recording will be created with that name.
 *
 *  The extension of the recording package is always @c .dtxrec.
 *
 *  If set to @c nil, the URL will reset to the default value.
 *
 *  The default value is a file name with the date and time of the recording, in the documents folder of the profiled app.
 */
@property (nonatomic, copy, null_resettable, readwrite) NSURL* recordingFileURL;

@end

NS_ASSUME_NONNULL_END
