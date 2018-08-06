//
//  DTXProfilerEvents.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 7/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

typedef NSString * DTXEventIdentifier;

#import "DTXBase.h"

NS_ASSUME_NONNULL_BEGIN
__BEGIN_DECLS

typedef NS_ENUM(NSUInteger, DTXEventStatus) {
	DTXEventStatusCompleted,
	DTXEventStatusError,
	
	DTXEventStatusCategory1,
	DTXEventStatusCategory2,
	DTXEventStatusCategory3,
	DTXEventStatusCategory4,
	DTXEventStatusCategory5,
	DTXEventStatusCategory6,
	DTXEventStatusCategory7,
	DTXEventStatusCategory8,
	DTXEventStatusCategory9,
	DTXEventStatusCategory10,
	DTXEventStatusCategory11,
	DTXEventStatusCategory12,
};

/*!
 * @function DTXProfilerMarkEventIntervalBegin
 *
 * @abstract
 * Begins an event interval.
 *
 * @param category
 * The category of this event.
 *
 * @param name
 * The name of this event.
 *
 * @param additionalInfo
 * Additional information to include with this event.
 *
 * @result
 * Returns a valid event identifier to be used with @c DTXProfilerMarkEventIntervalEnd.
 */
DTX_NOTHROW DTX_WARN_UNUSED_RESULT
extern DTXEventIdentifier DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* __nullable additionalInfo);

/*!
 * @function DTXProfilerMarkEventIntervalEnd
 *
 * @abstract
 * Ends an event interval.
 *
 * @param identifier
 * The identifier for the event which was provided by @c DTXProfilerMarkEventIntervalBegin.
 *
 * @param eventStatus
 * The status of this event.
 *
 * @param additionalInfo
 * Additional information to include with this event.
 */
DTX_NOTHROW
extern void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable additionalInfo);

/*!
 * @function DTXProfilerMarkEvent
 *
 * @abstract
 * Marks a point of interest in time with no duration.
 *
 * @param category
 * The category of this event.
 *
 * @param name
 * The name of this event.
 *
 * @param eventStatus
 * The status of this event.
 *
 * @param additionalInfo
 * Additional information to include with this event.
 */
DTX_NOTHROW
extern void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable additionalInfo);

__END_DECLS
NS_ASSUME_NONNULL_END
