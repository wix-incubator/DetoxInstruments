# Network Activity Instrument

The Network Activity instrument captures information about your app's network activity. It can record localhost information when the **Record localhost network** profiling preference is enabled.

![Network Activity](Resources/Instrument_NetworkActivity.png "Network Activity")

### Discussion

Use the information captured by this instrument to inspect your app's general network activity.

Network requests appear as segmented lines on the timeline in the timeline pane. Multiple requests made concurrently will appear below each other. Making many concurrent requests may hurt your app's performance.

Enable the **Record localhost network** profiling preference to capture requests sent to localhost to further investigate your app's network activity.

For an in-depth look at the profiling preferences, see [Profiling Preferences](Preferences_Profiling.md).

### Detail Pane

The detail pane includes your app's Network Activity at the time of the sample. If the **Record thread information** profiling preference was enabled during recording, the heaviest thread will also be noted for each sample.

![Network Activity Detail Pane](Resources/Instrument_NetworkActivity_DetailPane.png "Network Activity Detail Pane")

Samples will be highlighted in red (warning 3) when:

* The request failed with an error

Samples will be highlighted in orange (warning 2) when:

* The response' status code is below 200 or equal to or above 400

Samples will be highlighted in yellow (warning 1) when:

* The request is still pending and no response has been received yet

### Inspector Pane

For each sample, the inspector pane shows request and response information, such as headers, data and general information.

![Network Activity Inspector Pane](Resources/Instrument_NetworkActivity_InspectorPane.png "Network Activity Inspector Pane")

Images and text responses are previewed automatically. You can expand the preview into a new window by pressing the expand button (![Expand Button](Resources/Button_ExpandPreview.png)). You can also open, save as, or share the response file.

#### Requests Playground

You can open the selected request in the **Requests Playground** utility by clicking the **Open in Requests Playground** button. All the headers and data of the request will be transferred.

For more information, see [Requests Playground](RequestsPlayground.md).