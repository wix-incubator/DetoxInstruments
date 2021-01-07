//
//  DTXProfilerAPI.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 7/30/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#ifndef DTXProfilerAPI_h
#define DTXProfilerAPI_h

#import <DTXProfiler/DTXBase.h>
#import <DTXProfiler/DTXProfilerLogLevel.h>

NS_ASSUME_NONNULL_BEGIN
__BEGIN_DECLS

/*!
 * @function DTXProfilerAddTag
 *
 * @abstract
 * Adds a tag.
 *
 * @discussion
 * Tags are added chronologically.
 *
 * @param tag
 * The tag name to push.
 */
DTX_NOTHROW
extern void DTXProfilerAddTag(NSString* tag);

/*!
 * @function DTXProfilerAddLogEntry
 *
 * @abstract
 * Adds a log entry.
 *
 * @discussion
 * The message may be a multiline string.
 *
 * @param timestamp
 * The timestamp of the log line.
 *
 * @param level
 * The level of the log entry
 *
 * @param subsystem
 * The log subsystem
 *
 * @param category
 * The log category
 *
 * @param message
 * The log message to add
 */
DTX_NOTHROW
extern void DTXProfilerAddLogEntry(NSDate* timestamp, DTXProfilerLogLevel level, NSString* subsystem, NSString* category, NSString* message);

/*!
 * @function DTXProfilerAddLegacyLogEntry
 *
 * @abstract
 * Adds a log entry.
 *
 * @discussion
 * The message may be a multiline string.
 *
 * Log messages are added chronologically.
 *
 * @param message
 * The log message to add
 */
void DTXProfilerAddLegacyLogEntry(NSString* message) __attribute__((deprecated));

/*!
 * @function DTXProfilerAddLegacyLogEntryWithObjects
 *
 * @abstract
 * Adds a log entry with an array of object.
 *
 * @discussion
 * The message may be a multiline string.
 *
 * Log messages are added chronologically.
 *
 * @param message
 * The message to add
 *
 * @param objects
 * The objects to add
 */
DTX_NOTHROW
extern void DTXProfilerAddLegacyLogEntryWithObjects(NSString* message, NSArray* __nullable objects);


DTX_NOTHROW
extern void DTXProfilerAddLogLine(NSString* line) __attribute__((deprecated));

DTX_NOTHROW
extern void DTXProfilerAddLogLineWithObjects(NSString* line, NSArray* __nullable objects) __attribute__((deprecated));

__END_DECLS
NS_ASSUME_NONNULL_END

#endif /* DTXProfilerAPI_h */
