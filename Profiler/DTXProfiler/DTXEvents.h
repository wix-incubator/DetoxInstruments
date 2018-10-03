//
//  DTXProfilerEvents.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 7/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#ifndef DTXEvents_h
#define DTXEvents_h

#import <DTXProfiler/DTXBase.h>

typedef NSString * DTXEventIdentifier;

typedef NS_ENUM(NSUInteger, DTXEventStatus) {
	DTXEventStatusCompleted,
	DTXEventStatusError,
	DTXEventStatusCancelled
};

NS_ASSUME_NONNULL_BEGIN
__BEGIN_DECLS

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
extern void DTXProfilerMarkEventIntervalEnd(DTXEventIdentifier identifier, DTXEventStatus eventStatus, NSString* __nullable additionalInfo);

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

#endif /* DTXEvents_h */
