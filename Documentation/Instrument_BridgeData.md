# React Native Bridge Data Instrument

The Bridge Data instrument captures information about React Native bridge data passed in your app.

![React Native Bridge Data](Resources/Instrument_RNBridgeData.png "React Native Bridge Data")

### Discussion

Use the information captured by this instrument to inspect the data passed in your app's React Native bridge. The more data passed, the more processing needed in native and the JavaScript thread, and thus can lead to your app being less responsive.

### Detail Pane

The detail pane includes your app's React Native bridge data at the time of the sample; N➔JS (native to JavaScript) and JS➔N (JavaScript to native) are displayed in columns of delta as well as total.

![React Native Bridge Data Detail Pane](Resources/Instrument_BridgeData_DetailPane.png "React Native Bridge Data Detail Pane")