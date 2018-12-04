# `DTXProfilingConfiguration`/`DTXMutableProfilingConfiguration`

Profiling configuration object for the Profiler.

### Declaration

```objective-c
@interface DTXProfilingConfiguration : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>

@interface DTXMutableProfilingConfiguration : DTXProfilingConfiguration
```

```swift
open class DTXProfilingConfiguration : NSObject, NSCopying, NSMutableCopying, NSSecureCoding

open class DTXMutableProfilingConfiguration : DTXProfilingConfiguration
```

### Properties

#### `defaultProfilingConfiguration`/`default`

A newly created default profiling configuration object.

#### `samplingInterval`

The sampling interval of the Profiler.
The default value is `1.0`.

#### `numberOfSamplesBeforeFlushToDisk`

The minimum number of samples to keep in memory before flushing to disk.
Larger number of samples in memory will improve performance at the cost of memory use.
The default value is `200`.

#### `recordThreadInformation`

Record thread information during profiling.
The default value is `true`.

#### `collectStackTraces`

Symbolicate stack traces at runtime.
Symbolicating stack traces may introduce some performance hit.
The default value is `false`.

#### `symbolicateStackTraces`

Symbolicate stack traces at runtime.
Symbolicating stack traces may introduce some performance hit.
The default value is `false`.

#### `collectOpenFileNames`

Collect the names of open files for each sample.
The default value is `false`.

#### `recordNetwork`

Record network requests during profiling.
The default value is `true`.

#### `recordLocalhostNetwork`

Record localhost network requests during profiling.
Only relevant if `recordNetwork` is set to `true`.
The default value is `false`.

#### `disableNetworkCache`

Disables cache for network requests.
The default value is `false.`

#### `ignoredEventCategories`

A set of categories to ignore when profiling.
Use this property to prevent clutter in the Events instrument.
The default value is an empty set.

#### `recordLogOutput`

Record log output during profiling.
The default value is `true`.

#### `profileReactNative`

Profile React Native application.
Currently, only one active React Native bridge is supported.
The default value is `true`.

#### `recordReactNativeBridgeData`

Record React Native bridge data during profiling.
The default value is `false`.

#### `recordReactNativeTimersAsEvents`

Record React Native timers (created using `setTimeout()` in JavaScript) as events.
The default value is `false`.

#### `recordingFileURL`

The recording file URL to save to.
If this URL is a directory URL, a new recording will be created in that directory with the date and time of the recording.
If the URL is a file URL, a new recording will be created with that name.
The extension of the recording package is always `.dtxprof`.
If set to `nil`, the URL will reset to the default value.
The default value is a file name with the date and time of the recording, in the documents folder of the profiled app.