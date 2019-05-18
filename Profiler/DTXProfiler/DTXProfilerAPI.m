
#import "DTXProfilerAPI-Private.h"

NSString* const __DTXDidAddActiveProfilerNotification = @"__DTXDidAddActiveProfilerNotification";
NSString* const __DTXDidRemoveActiveProfilerNotification = @"__DTXDidRemoveActiveProfilerNotification";

pthread_mutex_t __active_profilers_mutex;
NSMutableSet<DTXProfiler*>* __activeProfilers;

void __DTXProfilerActiveProfilersInit(void)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		pthread_mutex_init(&__active_profilers_mutex, NULL);
		__activeProfilers = [NSMutableSet new];
	});
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

DTXEventIdentifier DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* __nullable startMessage)
{
	return __DTXProfilerMarkEventIntervalBegin(NSDate.date, category, name, startMessage, NO,NO , nil);
}

void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable endMessage)
{
	__DTXProfilerMarkEventIntervalEnd(NSDate.date, identifier, eventStatus, endMessage);
}

void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable message)
{
	__DTXProfilerMarkEvent(NSDate.date, category, name, eventStatus, message);
}
