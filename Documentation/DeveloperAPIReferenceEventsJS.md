# Events API Reference for React Native / JavaScript

The Events instrument lets you add lightweight instrumentation to your code for collection and visualization by Detox Instruments. You can specify interesting periods of time ('intervals') and single points in time ('events'). Each event can be marked as completed or errored, or as 12 different general-purpose categories, each displayed with its own color in the timeline pane.

Before using the provided developer APIs, first complete the [Profiler Framework Integration Guide](XcodeIntegrationGuide.md).

For React Native apps, you need to install the **`detox-instruments-react-native-utils`** package:

```shell
npm install detox-instruments-react-native-utils --save-prod
```

Import the Event class from the package:

```javascript
import { Event } from 'detox-instruments-react-native-utils';
```

### Usage

#### Intervals

```javascript
let event = new Event("Category", "Name");
event.beginInterval("Start message");
//Long interval
event.endInterval(Event.EventStatus.completed, "End message");
```

#### Single Points in Time

```javascript
Event.event("Category", "Name", Event.EventStatus.category3, "Message");
```

