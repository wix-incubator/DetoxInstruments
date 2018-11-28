# Profiling Options

Before profiling, you can set options that change how the profiling performs and what should be recorded. These options control the accuracy and amount of data collected at the expense of potential performance impact.

![Profiling Options](Resources/ProfilingOptions_ProfilingOptions.png "Profiling options")

### Configuration

The **Use default profiling configuration** option sets all other options to their default value. When enabled, profiling will be performed using the these default values. These defaults may change from time to time, depending on development and feedback considerations.

### Sampling Frequency

The **Sampling frequency** option configures how many samples should be collected every second. The more samples collected, the more accurate the profiling, at some expense of performance.

It is recommended to start with the default value and only increase sampling frequency if necessary.

### Threads

The **Record thread information** option controls whether any thread information is recorded during profiling. Recording thread information can provide additional performance metrics per thread. Normally, recording thread information is not an expensive operation and should be enabled unless absolutely not needed.

The **Collect stack traces** option enables the recording of the stack trace of the heaviest thread. This provides code symbol information for additional debugging purposes. This is a relatively inexpensive operation, but depending on the sampling frequency, may have a slight performance cost.

The **Symbolicate stack traces** option enables the runtime symbolication of symbols collected in stack traces. This further assists development by creating human-readable symbols. This is a relatively inexpensive operation, but depending on the sampling frequency, may have a slight performance cost.

### Disk Usage

The **Collect open file names** option enables the collection of names of files open in the app at the time of sampling. This is a relatively inexpensive operation, but depending on the sampling frequency, may have a slight performance cost.

### Network

The **Record network** option controls whether any network traffic is recorded, including headers and data. Depending on your app's activity, this can take a small-to-moderate toll on performance. If network recording is not necessary, you can turn this option off to save performance.

The **Record localhost network** option extends the network recording to localhost connections as well. Depending on your app's activity, this may introduce a lot of unwanted noise. Enable if you need to profile or debug localhost connections.

The **Disable network cache** option controls whether network cache should be disabled for requests the app makes while recording.

### Events

The **Ignored Categories** button presents the **Ignored Events Categories** screen.

![Ignored Events Categories](Resources/ProfilingOptions_IgnoredEventsCategories.png "Ignored Events Categories")

In this screen, you can add Events categories that will be ignored when recording. Use this to save performance and lower clutter. For an in-depth look at the Events instrument, see [Events Instrument](Instrument_Events.md).

### Log

The **Collect log output** options enables the recording of your app's log output. This can be very useful for cross-referencing your debug log output with profiling samples of your app. This is an inexpensive operation, but depending on the log output amount, may have a slight performance cost.

### React Native

The **Profile React Native (if available)** options controls the React Native profiling systems in Detox Instruments and its Profiler framework. These systems provide information such as JavaScript thread performance, bridge calls and bridge data, which can be very helpful when debugging apps with React Native usage.

The **Record bridge data** option controls whether React Native bridge data is recorded during profiling. Depending on your app's activity, this can take a small-to-moderate toll on performance. If bridge data recording is not necessary, you can turn this option off to save performance.

The **Record timers as events** options controls whether React Native timers, created in JavaScript using `setTimeout()`, should be recorded as events and displayed in the Events instrument. This option requires that the **`detox-instruments-react-native-utils`** package be installed in your React Native app. For more information, see [Events API Reference for React Native / JavaScript](DeveloperAPIReferenceEventsJS.md).

### Time Limit

The **Time limit** option sets a hard time limit on recording duration. You can set the value in seconds, minutes or hours. The default is 2 minutes.