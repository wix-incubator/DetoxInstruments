//
//  DTXProfilerAPI.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 7/30/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#ifndef DTXProfilerAPI_h
#define DTXProfilerAPI_h

#import "DTXBase.h"

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
 * @function DTXProfilerAddLogLine
 *
 * @abstract
 * Adds a log line.
 *
 * @discussion
 * The line may be a multiline string.
 *
 * Log lines are added chronologically.
 *
 * @param line
 * The log line to add.
 */
DTX_NOTHROW
extern void DTXProfilerAddLogLine(NSString* line);

/*!
 * @function DTXProfilerAddLogLineWithObjects
 *
 * @abstract
 * Adds a log line and an array of object.
 *
 * @discussion
 * The line may be a multiline string.
 *
 * Log lines are added chronologically.
 *
 * @param line
 * The line to add.
 *
 * @param objects
 * The objects to add.
 */
DTX_NOTHROW
extern void DTXProfilerAddLogLineWithObjects(NSString* line, NSArray* __nullable objects);

__END_DECLS
NS_ASSUME_NONNULL_END

#endif /* DTXProfilerAPI_h */
