# Detox Instruments

## About

Detox Instruments is a performance–analysis and testing framework, designed to help developers profile their mobile apps in order to better understand and optimize their behavior and performance.

![Detox Instruments](Documentation/Resources/Readme_Intro.png "Detox Instruments")

Incorporating Detox Instruments into the development workflow from the beginning of the app development process can save time later by helping find issues early in the development cycle. Detox Instruments has first–class support for React Native, allowing seamless analysis of the entire app lifecycle in one place.

Detox Instruments supports profiling the following metrics:

* Performance Profiling
	* CPU Load
		* Per Thread Breakdown of CPU Load
		* Heaviest Stack Trace Sampling
		* Automatic Runtime Symbolication of Stack Traces
	* Memory Usage
	* User Interface FPS (Frames per Second)
	* Disk Activity (Reads and Writes, Open File Names)
* Network Activity
	* Full Request and Response Header and Data Collection and Inspection
* Log Output Recording
* React Native Profiling
	* JavaScript Thread CPU Load
		* JavaScript Stack Trace Sampling **(Coming Soon)**
		* Automatic Runtime Symbolication of Stack Traces Using Source Maps **(Coming Soon)**
	* Bridge Call Counters
	* Bridge Data Counters
		* Bridge Data Collection **(Coming Soon)**

For a list of available instruments and their description, see [Available Instruments](Documentation/AvailableInstruments.md).

## Installation

The Detox Instruments application requires macOS 10.13 and higher. The Profiler framework supports iOS 10 and higher.

Detox Instruments is installed using Homebrew Cask, by running the following commands:

```bash
brew tap wix/brew
brew cask install detox-instruments
```

This will install Detox Instruments under `/Applications`.

## Integration with Mobile App

In order to begin profiling your app, you need to integrate the Profiler framework in your app's project. See [Profiler Framework Integration Guide](Documentation/XcodeIntegrationGuide.md) for more information.

## Profiling an App

Once you've installed Detox Instruments and integrated the Profiler framework with your app's project, you can start profiling your app.

#### The App Selection Dialog

After launching Detox Instruments or selecting **File** ➔ **New Recording...**, you will be presented with an app selection dialog, displaying a list of available apps to profile. Launch your app on your mobile device or simulator and your app will appear in the list.

![App Discovered](Documentation/Resources/Readme_Discovered.png "App Discovered")

To start profiling, select your app and click on the Profile button. To configure profiling options, such as sampling frequency and recording features, click on the Options button. For an in-depth look at profiling options, see [Profiling Options](Documentation/ProfilingOptions.md).

#### The Recording Document

A recording document is used to initiate new profiling and view and analyze the results of profiling. You create a new recording document by selecting **File** ➔ **New Recording...** and choosing an app to profile.

![Detox Instruments](Documentation/Resources/Readme_Intro.png "Detox Instruments")

You can also save and reopen recording documents in which you’ve collected data previously. A recording document can contain a lot of extremely detailed information, and this information is presented to you through a number of panes and areas.

For detailed information on the recording document, see [The Recording Document](Documentation/RecordingDocument.md).

#### Instruments

Detox Instruments includes many instruments to analyze many aspects of your app.

![Instruments](Documentation/Resources/RecordingDocument_TimelinePane.png "Instruments")

For a list of available instruments and their description, see [Available Instruments](Documentation/AvailableInstruments.md).

## Acknowledgements

See [Acknowledgements](Documentation/Acknowledgements.md)