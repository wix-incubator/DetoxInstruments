# Detox Instruments

## About

Detox Instruments is a performance–analysis and testing framework, designed to help developers profile their mobile apps in order to better understand and optimize their app's behavior and performance. In addition, Detox Instruments includes utilities for managing your app's resources, such user defaults, pasteboard, cookies, etc.

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
* Developer Events
* Log Output Recording
* React Native Profiling
  * JavaScript Thread CPU Load
  * Bridge Call Counters
  * Bridge Data Counters
  * Bridge Data Collection

For a list of available instruments and their description, see [Available Instruments](Documentation/AvailableInstruments.md).

Detox Instruments includes the following app management utilities:

- Container Files
  - Download and upload files and folders to your app's container
- Pasteboard
  - Copy and paste items between your Mac and your device
- User Defaults
  - Modify user defaults in real time
- Cookies
  - Create and modify the app's HTTP cookies

For a list of available app management utilities and their description, see [App Management](Documentation/AppManagement.md).

## Installation

The Detox Instruments application requires macOS 10.14 (Mojave) and higher. The Profiler framework supports iOS 10 and higher.

Detox Instruments is installed using Homebrew Cask, by running the following commands:

```bash
brew tap wix/brew
brew cask install detox-instruments
```

This will install Detox Instruments under `/Applications`.

## Integration with Your App's Project

In order to begin profiling your app, you need to integrate the Profiler framework in your app's project. See [Profiler Framework Integration Guide](Documentation/XcodeIntegrationGuide.md) for more information.

### Developer API Reference

By integrating Detox Instruments in your app, many of the included instruments can automatically collect data. Some instruments require you to explicitly call the provided APIs so that specific data can be collected.

See the [Developer API Reference](Documentation/DeveloperAPIReferenceIntro.md) for more information.

## Profiling an App

Once you've installed Detox Instruments and integrated the Profiler framework with your app's project, you can start profiling your app.

### The App Selection Dialog

After launching Detox Instruments or selecting **File** ➔ **New Recording...**, you will be presented with an app selection dialog, displaying a list of available apps to profile. Launch your app on your mobile device or simulator and your app will appear in the list.

See [App Discovery](Documentation/AppDiscovery.md) for more information and troubleshooting.

![App Discovered](Documentation/Resources/Readme_Discovered.png "App Discovered")

To start profiling, select your app and click on the Profile button. 

To manage profiling options, such as sampling frequency and recording features, see **Profiling** in the preferences. For an in-depth look at profiling preferences, see [Profiling Preferences](Documentation/Preferences_Profiling.md).

### App Management

![App Management](Documentation/Resources/Management_All.png "App Management")

To manage your app, click on the **Manage** button (![Gear Button](Documentation/Resources/Button_Manage.png)) in the app selection dialog. You can manage multiple apps at the same time. For an in-depth look at app management, see [App Management](Documentation/AppManagement.md).

### The Recording Document

A recording document is used to initiate new profiling and view and analyze the results of profiling. You create a new recording document by selecting **File** ➔ **New Recording...** and choosing an app to profile.

![Detox Instruments](Documentation/Resources/Readme_Document.png "Detox Instruments")

You can also save and reopen recording documents in which you’ve collected data previously. A recording document can contain a lot of extremely detailed information, and this information is presented to you through a number of panes and areas.

For detailed information on the recording document, see [The Recording Document](Documentation/RecordingDocument.md).

For detailed information on the preferences, see [General Preferences](Documentation/Preferences_General.md)

### Instruments

Detox Instruments includes many instruments to analyze many aspects of your app.

![Instruments](Documentation/Resources/RecordingDocument_TimelinePane.png "Instruments")

For a list of available instruments and their description, see [Available Instruments](Documentation/AvailableInstruments.md).

### Requests Playground

![Requests Playground](Documentation/Resources/RequestsPlayground.png "Requests Playground")

Detox Instruments includes a utility for replaying and modifying network requests, called Requests Playground. These requests can be saved as a document for future reference and testing. For an in-depth look at app management, see [Requests Playground](Documentation/RequestsPlayground.md).

## Acknowledgements

See [Acknowledgements](Documentation/Acknowledgements.md)

## Installation Troubleshooting

- If Homebrew complains about a conflict in the `wix/brew` tap, run `brew untap wix/brew && brew tap wix/brew` and install again
- If installation still fails, **run `brew doctor` and fix all issues & warnings**
