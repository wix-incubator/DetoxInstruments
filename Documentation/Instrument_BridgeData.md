# React Native Bridge Data Instrument

The Bridge Data instrument captures information about React Native bridge data passed in your app.

![React Native Bridge Data](Resources/Instrument_RNBridgeData.png "React Native Bridge Data")

### Discussion

Use the information captured by this instrument to inspect the data passed in your app's React Native bridge. The more data passed, the more processing needed in native and the JavaScript thread, and thus can lead to your app being less responsive.

### Detail Pane

The detail pane includes your app's React Native bridge data at the time of the sample; N ➔ JS (native to JavaScript) and JS ➔ N (JavaScript to native) are displayed in columns of delta as well as total.

If the **Record bridge data** option was enabled during recording, you can select to view **Samples** or **Bridge Data** in the navigation bar.

![React Native Bridge Data Navigation Menu](/Users/lnatan/Desktop/Code/DetoxInstruments/Documentation/Resources/Instrument_RNBridgeData_Menu.png "React Native Bridge Data Navigation Menu")

For an in-depth look at profiling options, see [Profiling Options](ProfilingOptions.md).

#### Samples

![CPU Usage Detail Pane](Resources/Instrument_RNBridgeData_DetailPane.png "Bridge Data Detail Pane")

#### Bridge Data

![CPU Usage Detail Pane](Resources/Instrument_RNBridgeData_DetailPane_BridgeData.png "Bridge Data Detail Pane")

### Inspector

#### Bridge Data

If the **Record bridge data** option was enabled during recording, the inspector pane shows information about React Native bridge data packets.

![CPU Usage Inspector Pane](Resources/Instrument_RNBridgeData_InspectorPane_BridgeData.png "Bridge Data Inspector Pane")