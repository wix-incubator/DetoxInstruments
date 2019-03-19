# Events API Reference for Objective C & Swift

The Events instrument lets you add lightweight instrumentation to your code for collection and visualization by Detox Instruments. You can specify interesting periods of time ('intervals') and single points in time ('events'). Each event can be marked as completed or errored, or as 12 different general-purpose categories, each displayed with its own color in the timeline pane.

Before using the provided developer APIs, first complete the [Profiler Framework Integration Guide](XcodeIntegrationGuide.md).

Import the framework:

```objective-c
#import <DTXProfiler/DTXEvents.h>
```

```swift
import DTXProfiler.DTXEvents
```

## Usage

#### Intervals

```objective-c
DTXEventIdentifier identifier = DTXProfilerMarkEventIntervalBegin(@"Category", @"Name", @"Message at start");
//Long interval
DTXProfilerMarkEventIntervalEnd(identifier, DTXEventStatusCompleted, @"Message at end");
```

```swift
let identifier = DTXProfilerMarkEventIntervalBegin("Category", "Name", "Message at start")
//Long interval
DTXProfilerMarkEventIntervalEnd(identifier, .completed, "Message at end")
```

#### Single Points in Time

```objective-c
DTXProfilerMarkEvent(@"Category", @"Name", DTXEventStatusCompleted, @"Message");
```

```swift
DTXProfilerMarkEvent("Category", "Name", .completed, "Message")
```



### Functions

#### `DTXProfilerMarkEventIntervalBegin`

Begins an event interval.

##### Declaration

```objective-c
DTXEventIdentifier DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* *__nullable* startMessage)
```

```swift
func DTXProfilerMarkEventIntervalBegin(_ category: String, _ name: String, _ startMessage: String?) -> String
```

##### Parameters

###### category

The category of this event

###### name

The name of this event

###### startMessage

The start message to include with this event

##### Return Value

Returns a valid event identifier to be used with `DTXProfilerMarkEventIntervalEnd`.

####  `DTXProfilerMarkEventIntervalEnd`

Ends an event interval.

##### Declaration

```objective-c
void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable endMessage)
```

```swift
func DTXProfilerMarkEventIntervalEnd(_ identifier: String, _ eventStatus: DTXEventStatus, _ endMessage: String?)
```

##### Parameters

###### identifier

The identifier for the event which was provided by `DTXProfilerMarkEventIntervalBegin`

###### eventStatus

The status of this event

###### endMessage

The end message to include with this event

#### `DTXProfilerMarkEvent`

Marks a point of interest in time with no duration.

##### Declaration

```objective-c
void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable message)
```

```swift
func DTXProfilerMarkEvent(_ category: String, _ name: String, _ eventStatus: DTXEventStatus, _ message: String?)
```

##### Parameters

###### category

The category of this event

###### name

The name of this event

###### eventStatus

The status of this event

###### message

A message to include with this event.

### Enums

#### `DTXEventStatus`

Represents the status of events. Mark events ended in error with `DTXEventStatusError`/`.error` and cancelled events with `DTXEventStatusCancelled`/`.cancelled`.

