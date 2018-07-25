
#import "DTXProfiler-Private.h"

pthread_mutex_t __active_profilers_mutex;
NSMutableSet<DTXProfiler*>* __activeProfilers;

__attribute((constructor))
static void __DTXProfilerActiveProfilersInit()
{
	__activeProfilers = [NSMutableSet new];
	pthread_mutex_init(&__active_profilers_mutex, NULL);
}

/**
 *  Push a sample group.
 *
 *  Subsequent samples will be pushed into this group.
 *
 *  @param name The name of the sample group to push.
 */
void DTXProfilerPushSampleGroup(NSString* name)
{
	__DTXProfilerPushSampleGroup(NSDate.date, name);
}

/**
 *  Pop a sample group.
 *
 *  Subsequent samples will be pushed into the parent group.
 */
void DTXProfilerPopSampleGroup(void)
{
	__DTXProfilerPopSampleGroup(NSDate.date);
}

/**
 *  Adds a tag.
 *
 *  Tags are added chronologically.
 *
 *  @param tag The tag name to push.
 */
void DTXProfilerAddTag(NSString* tag)
{
	__DTXProfilerAddTag(NSDate.date, tag);
}

/**
 *  Adds a log line.
 *
 *  The line may be a multiline string.
 *
 *  Log lines are added chronologically.
 *
 *  @param line The line to add.
 */
void DTXProfilerAddLogLine(NSString* line)
{
	__DTXProfilerAddLogLine(NSDate.date, line);
}

/**
 *  Adds a log line and an array of object.
 *
 *  The line may be a multiline string.
 *
 *  Log lines are added chronologically.
 *
 *  @param line The line to add.
 *  @param objects The objects to add.
 */
void DTXProfilerAddLogLineWithObjects(NSString* line, NSArray* __nullable objects)
{
	__DTXProfilerAddLogLineWithObjects(NSDate.date, line, objects);
}

DTXEventIdentifier DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* __nullable additionalInfo)
{
	return __DTXProfilerMarkEventIntervalBegin(NSDate.date, category, name, additionalInfo);
}

void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable additionalInfo)
{
	__DTXProfilerMarkEventIntervalEnd(NSDate.date, identifier, eventStatus, additionalInfo);
}

void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable additionInfo)
{
	__DTXProfilerMarkEvent(NSDate.date, category, name, eventStatus, additionInfo);
}
