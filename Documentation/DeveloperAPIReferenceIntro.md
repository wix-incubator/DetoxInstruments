# Developer API Reference

By integrating Detox Instruments in your app, many of the included instruments can automatically collect data. Some instruments require you to explicitly call the provided APIs so that specific data can be collected.

Before using the provided developer APIs, first complete the [Profiler Framework Integration Guide](XcodeIntegrationGuide.md).

For Objective C and Swift, simply integrating the Profiler framework is enough to access the API.

For React Native apps, you need to install the **detox-instruments-react-native-utils** package:

```shell
npm install detox-instruments-react-native-utils --save-prod
```

### Events

The Events instrument lets you add lightweight instrumentation to your code for collection and visualization by Detox Instruments. You can specify interesting periods of time ('intervals') and single points in time ('events'). Each event can be marked as completed or errored, or as 12 different general-purpose categories, each displayed with its own color in the timeline pane.

For Objective C and Swift code, see [Events API Reference for Objective C & Swift](DeveloperAPIReferenceEventsObjCSwift.md)

For React Native / JavaScript code, see [Events API Reference for React Native / JavaScript](DeveloperAPIReferenceEventsJS.md)
