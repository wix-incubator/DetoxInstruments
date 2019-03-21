//
//  WixProfileCallback.m
//  DTXProfiler
//
//  Created by Muhammad Abed El Razek on 18/03/2019.
//  Copyright © 2019 Wix. All rights reserved.
//

@import ObjectiveC;
@import Darwin;
#import <Foundation/Foundation.h>
#import <DTXProfiler/DTXEvents.h>
#import "DTXReactNativeProfilerCallback.h"
#import "DTXProfiler-Private.h"


typedef struct {
  const char *key;
  int key_len;
  const char *value;
  int value_len;
} systrace_arg_t;

typedef struct {
  char *(*start)(void);
  void (*stop)(void);
  
  void (*begin_section)(uint64_t tag, const char *name, size_t numArgs, systrace_arg_t *args);
  void (*end_section)(uint64_t tag, size_t numArgs, systrace_arg_t *args);
  
  void (*begin_async_section)(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args);
  void (*end_async_section)(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args);
  
  void (*instant_section)(uint64_t tag, const char *name, char scope);
  
  void (*begin_async_flow)(uint64_t tag, const char *name, int cookie);
  void (*end_async_flow)(uint64_t tag, const char *name, int cookie);
} RCTProfileCallbacks;


static dispatch_once_t onceSectionsToken;
static NSMutableDictionary* threadSections = nil;
static NSMutableDictionary* asyncSections = nil;
static NSMutableDictionary* asyncFlows = nil;
static DTXProfilingConfiguration* dtxConfig = nil;

#pragma mark help-methods
void* dtxBeginEvent(const char* eventName, const char* category, const char* additionalInfo)
{
	NSLog(@"dtxBeginEvent category : %s", category);
	DTXEventIdentifier identifier = __DTXProfilerMarkEventIntervalBegin(NSDate.date,
																		[NSString stringWithUTF8String:category],
																		[NSString stringWithUTF8String:eventName],
																		[NSString stringWithUTF8String:additionalInfo],
																		NO,YES,nil);
  	return (void*)CFBridgingRetain(identifier);
}

void dtxEndEvent(void* eventId)
{
	if(eventId)
	{
		__DTXProfilerMarkEventIntervalEnd(NSDate.date,
										  (__bridge DTXEventIdentifier _Nonnull)(eventId),
										  DTXEventStatusCompleted, nil);
	}
}

//NSThread extension
@implementation NSThread (GetSequenceNumber)
- (NSInteger)sequenceNumber
{
  	return [[self valueForKeyPath:@"private.seqNum"] integerValue];
}
@end


NSString* getOptionalArgument(size_t numArgs, systrace_arg_t *args)
{
	if (numArgs == 0)
	{
		return @"";
	}
	NSMutableString* output = [[NSMutableString alloc] init];
	if (numArgs == 1)
	{
		[output appendFormat:@"%@", [NSString stringWithUTF8String:args[0].value]];
	}
	else
	{
		[output appendString:@"{ "];
		for (size_t i = 0; i < numArgs; i++)
		{
			  [output appendFormat:@"%@: %@", [NSString stringWithUTF8String:args[i].key], [NSString stringWithUTF8String:args[i].value]];
			  if (i < numArgs - 1)
			  {
				  [output appendString:@", "];
			  }
		}
		[output appendString:@" }"];
	}
	return output;
}


char* wixProfileStart()
{
	return 0;
}

void wixProfileStop(){}

void wixProfileBeginSection(__unused uint64_t tag, const char *name, size_t numArgs, systrace_arg_t *args)
{
	dispatch_once(&onceSectionsToken, ^{
		threadSections = [[NSMutableDictionary alloc] init];
	});

	void* eventId = dtxBeginEvent(name, "Section",  [getOptionalArgument(numArgs, args) UTF8String]);
	@synchronized(threadSections){
		NSInteger threadId = [[NSThread currentThread] sequenceNumber];
		NSMutableArray* sections = [threadSections objectForKey:@(threadId)];
		if (sections == nil)
		{
			sections = [[NSMutableArray alloc] init];
			[sections addObject:(__bridge id _Nonnull) eventId];
			[threadSections setObject:sections forKey:@(threadId)];
		}
		else
		{
		  [sections addObject:(__bridge id _Nonnull) eventId];
		}
	}
}

void wixProfileEndSection(__unused uint64_t tag, __unused size_t numArgs, __unused systrace_arg_t *args)
{
  @synchronized(threadSections){
    NSInteger threadId = [[NSThread currentThread] sequenceNumber];
    NSMutableArray* sections = [threadSections objectForKey:@(threadId)];
    if (sections != nil)
	{
		void* eventId = (__bridge void*)[sections lastObject];
		if (eventId)
		{
			dtxEndEvent(eventId);
			[sections removeLastObject];
		}
    }
  }
}

void wixProfileBeginAsyncSection(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		asyncSections = [[NSMutableDictionary alloc] init];
	});
	void* eventId = dtxBeginEvent(name, "AsyncSection",  [getOptionalArgument(numArgs, args) UTF8String]);
	NSNumber* key = @(cookie);
	@synchronized(asyncSections) {
		[asyncSections setObject:(__bridge id _Nonnull) eventId forKey:key];
	}
}

void wixProfileEndAsyncSection(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args)
{
	NSNumber* key = @(cookie);
	@synchronized(asyncSections) {
		void* eventId = (__bridge void*)[asyncSections objectForKey:key];
		if (eventId)
		{
			dtxEndEvent(eventId);
			[asyncSections removeObjectForKey:key];
		}
	}
}

void wixProfileInstantSection(uint64_t tag, const char *name, char scope)
{
	__DTXProfilerMarkEvent(NSDate.date,
						   @"InstantSection",
						   [NSString stringWithUTF8String:name],
						   DTXEventStatusCompleted,
						   nil);
}

void wixProfileBeginAsyncFlow(uint64_t tag, const char *name, int cookie)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		asyncFlows = [[NSMutableDictionary alloc] init];
	});
	void* eventId = dtxBeginEvent(name, "AsyncFlow", "");
	NSNumber* key = @(cookie);
	@synchronized(asyncFlows) {
		[asyncFlows setObject:(__bridge id _Nonnull) eventId forKey:key];
	}
}

void wixProfileEndAsyncFlow(uint64_t tag, const char *name, int cookie)
{
	NSNumber* key = @(cookie);
	@synchronized(asyncFlows) {
		void* eventId = (__bridge void*)[asyncFlows objectForKey:key];
		if (eventId)
		{
			dtxEndEvent(eventId);
			[asyncFlows removeObjectForKey:key];
		}
	}
}

RCTProfileCallbacks wixProfileCallbacks = {
	wixProfileStart,
	wixProfileStop,
	wixProfileBeginSection,
	wixProfileEndSection,
	wixProfileBeginAsyncSection,
	wixProfileEndAsyncSection,
	wixProfileInstantSection,
	wixProfileBeginAsyncFlow,
	wixProfileEndAsyncFlow
};

void startListening()
{
	void (*registerCallbacks)(RCTProfileCallbacks *) = dlsym(RTLD_DEFAULT, "RCTProfileRegisterCallbacks");
	if(registerCallbacks != NULL)
	{
		registerCallbacks(&wixProfileCallbacks);
	}
}
