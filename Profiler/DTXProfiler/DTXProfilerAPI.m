
#import "DTXProfilerAPI-Private.h"

NSString* const __DTXDidAddActiveProfilerNotification = @"__DTXDidAddActiveProfilerNotification";
NSString* const __DTXDidRemoveActiveProfilerNotification = @"__DTXDidRemoveActiveProfilerNotification";

pthread_mutex_t __active_profilers_mutex;
NSMutableSet<DTXProfiler*>* __activeProfilers;

void __DTXProfilerActiveProfilersInit(void)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		pthread_mutexattr_t attr;
		pthread_mutexattr_init(&attr);
		pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&__active_profilers_mutex, &attr);
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

void DTXProfilerAddLogLine(NSString* line)
{
	__DTXProfilerAddLogLineWithObjects(NSDate.date, line, nil);
}

void DTXProfilerAddLogLineWithObjects(NSString* line, NSArray* __nullable objects)
{
	__DTXProfilerAddLogLineWithObjects(NSDate.date, line, objects);
}

void DTXProfilerAddTimestampedLogLine(NSDate* timestamp, NSString* line)
{
	__DTXProfilerAddLogLineWithObjects(timestamp, line, nil);
}

void DTXProfilerAddTimestampedLogLineWithObjects(NSDate* timestamp, NSString* line, NSArray* __nullable objects)
{
	__DTXProfilerAddLogLineWithObjects(timestamp, line, objects);
}

DTXEventIdentifier DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* __nullable startMessage)
{
	return __DTXProfilerMarkEventIntervalBegin(NSDate.date, category, name, startMessage, _DTXEventTypeSignpost, nil);
}

void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable endMessage)
{
	__DTXProfilerMarkEventIntervalEnd(NSDate.date, identifier, eventStatus, endMessage);
}

void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable message)
{
	__DTXProfilerMarkEvent(NSDate.date, category, name, eventStatus, message, _DTXEventTypeSignpost);
}

//Not exposed in headers but public SPI.

//DTXEventIdentifier DTXProfilerMarkActivityIntervalBegin(NSString* category, NSString* name, NSString* __nullable startMessage)
//{
//	return __DTXProfilerMarkEventIntervalBegin(NSDate.date, category, name, startMessage, _DTXEventTypeDetoxLifecycle, nil);
//}

//void DTXProfilerMarkActivityEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable message)
//{
//	__DTXProfilerMarkEvent(NSDate.date, category, name, eventStatus, message, _DTXEventTypeActivity);
//}

DTXEventIdentifier DTXProfilerMarkDetoxLifecycleIntervalBegin(NSString* category, NSString* name, NSString* __nullable startMessage)
{
	return __DTXProfilerMarkEventIntervalBegin(NSDate.date, category, name, startMessage, _DTXEventTypeDetoxLifecycle, nil);
}

void DTXProfilerMarkDetoxLifecycleEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable message)
{
	__DTXProfilerMarkEvent(NSDate.date, category, name, eventStatus, message, _DTXEventTypeDetoxLifecycle);
}

__attribute__((destructor))
static void _bestEffortStopActiveProfilers()
{
	dispatch_group_t wait_group = dispatch_group_create();
	
	//Copy here to prevent mutation during iteration. This is only needed here.
	[__activeProfilers.copy enumerateObjectsUsingBlock:^(DTXProfiler * _Nonnull profiler, BOOL * _Nonnull stop) {
		dispatch_group_enter(wait_group);
		[profiler stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
			dispatch_group_leave(wait_group);
		}];
	}];
	
	dispatch_group_wait(wait_group, DISPATCH_TIME_FOREVER);
}
