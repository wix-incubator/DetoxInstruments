# Profiler API Reference for Objective C & Swift

In addition to profiling your app live with Detox Instruments, you can start recordings in code for finer-grained control and testing scenarios where live recording is not applicable, such as app launch. This can be achieved with the Profiler API.

Before using the provided developer APIs, first complete the [Profiler Framework Integration Guide](XcodeIntegrationGuide.md).

#### Usage Example

```objective-c
#import <DTXProfiler/DTXProfiler.h>

DTXMutableProfilingConfiguration* configuration = DTXMutableProfilingConfiguration.defaultProfilingConfiguration;
configuration.recordingFileURL = //Set the recording document URL here

DTXProfiler* profiler = [[DTXProfiler alloc] init];
[profiler startProfilingWithConfiguration:configuration];
//...
[profiler stopProfilingWithCompletionHandler: ^(NSError* error) {
	NSLog(@"Finished recording with %@.", error.localizedDescription ?: @"no error");
}];
```

```swift
import DTXProfiler

let configuration = DTXMutableProfilingConfiguration.default()
		configuration.recordingFileURL = //Set the recording document URL here

let profiler = DTXProfiler()
		profiler.startProfiling(with: configuration)
//...
profiler.stopProfiling { error in
			print("Finished profiling with \(error?.localizedDescription ?? "no error").")
		}
```

## Classes

[`DTXProfilingConfiguration` & `DTXMutableProfilingConfiguration`](DeveloperAPIReferenceDTXProfilerConfigurationObjCSwift.md)

[`DTXProfiler`](DeveloperAPIReferenceDTXProfilerObjCSwift.md)

