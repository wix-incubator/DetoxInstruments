# Async Storage Instrument

The Async Storage instrument captures information about React Native async storage fetches and saves in the profiled app.

![React Native Async Storage](Resources/Instrument_RNAsyncStorage.png "React Native Async Storage")

### Discussion

Use the information captured by this instrument to inspect async storage fetches and saves. 

If the **Record async storage data** preference was enabled during recording, async storage data captured will appear in the inspector pane. For an in-depth look at the profiling preferences, see [Profiling Preferences](Preferences_Profiling.md).

### Detail Pane

The detail pane displays fetch and save samples, as well as general information about each operation, such as the operation type, duration and count.

![React Native Async Storage Navigation Menu](Resources/Instrument_RNAsyncStorage_Menu.png "React Native Async Storage Navigation Menu")

#### Fetches

![React Native Async Storage Fetches Detail Pane](Resources/Instrument_RNAsyncStorage_DetailPane.png "React Native Async Storage Fetches Detail Pane")

#### Saves

![React Native Async Storage Saves Detail Pane](Resources/Instrument_RNAsyncStorage_DetailPane_Saves.png "React Native Async Storage Saves Detail Pane")

### Inspector

If the **Record async storage data** preference was enabled during recording, async storage data captured will appear in addition to general information.

![CPU Usage Inspector Pane](Resources/Instrument_RNAsyncStorage_InspectorPane.png "Bridge Data Inspector Pane")