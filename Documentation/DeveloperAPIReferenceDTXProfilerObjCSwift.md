# `DTXProfiler`

Profiler objects are used to record profiling sessions.
Profiling configuration is achieved through `DTXProfilingConfiguration` instances.

### Declaration

```objective-c
@interface DTXProfiler : NSObject
```

```swift
open class DTXProfiler : NSObject
```

### Methods

#### `startProfilingWithConfiguration:`

Starts a profiling recording with the provided configuration.

##### Declaration

```objective-c
- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;
```

```swift
open func startProfiling(with configuration: DTXProfilingConfiguration)
```

##### Parameters

###### `configuration`

The configuration to use for profiling.

#### `continueProfilingWithConfiguration:`

Continues an existing profiling recording with the provided configuration, or if one does not exist, starts a new profiling recording.
If a recording is continued, the previous configuration is used.

##### Declaration

```objective-c
- (void)continueProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;
```

```swift
open func continueProfiling(with configuration: DTXProfilingConfiguration)
```

##### Parameters

###### `configuration`

The configuration to use for profiling.

#### `stopProfilingWithCompletionHandler:`

Stops the profiling recording.
If a completion handler is provided, it is called after the recording is saved to disk.
In most cases, this is called soon after calling `stopProfilingWithCompletionHandler:`,
however there may be cases when the stop operation may take a while to complete.
The completion handler is called on a background queue.

##### Declaration

```objective-c
- (void)stopProfilingWithCompletionHandler:(void(^ __nullable)(NSError* __nullable error))completionHandler;
```

```swift
open func stopProfiling(completionHandler: ((Error?) -> Void)? = nil)
```

##### Parameters

###### `completionHandler`

Completion handler called after the recording is saved to disk.

### Properties

#### `isRecording`

A Boolean value indicating whether there is currently a recording in progress.

#### `profilingConfiguration`

The profiling configuration provided to `startProfilingWithConfiguration:`. Will be null before calling that method.

