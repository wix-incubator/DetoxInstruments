//
//  DTXReactNativeProfilerSupport.m
//  DTXProfiler
//
//  Created by Muhammad Abed El Razek on 18/03/2019.
//  Copyright © 2019 Wix. All rights reserved.
//

@import ObjectiveC;
@import Darwin;
@import JavaScriptCore;
#import <Foundation/Foundation.h>
#import <DTXProfiler/DTXEvents.h>
#import "DTXReactNativeProfilerSupport.h"
#import "DTXProfiler-Private.h"

#pragma mark React Native Structs

typedef struct
{
	const char *key;
	int key_len;
	const char *value;
	int value_len;
}
systrace_arg_t;

typedef struct
{
	char *(*start)(void);
	void (*stop)(void);
	
	void (*begin_section)(uint64_t tag, const char *name, size_t numArgs, systrace_arg_t *args);
	void (*end_section)(uint64_t tag, size_t numArgs, systrace_arg_t *args);
	
	void (*begin_async_section)(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args);
	void (*end_async_section)(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args);
	
	void (*instant_section)(uint64_t tag, const char *name, char scope);
	
	void (*begin_async_flow)(uint64_t tag, const char *name, int cookie);
	void (*end_async_flow)(uint64_t tag, const char *name, int cookie);
}
RCTProfileCallbacks;

#pragma Implementation

#pragma mark Helper Methods
DTX_ALWAYS_INLINE
static DTXEventIdentifier __startEvent(NSDate* timestamp, const char* eventName, const char* category, const char* additionalInfo)
{
	return __DTXProfilerMarkEventIntervalBegin(timestamp, @(category), @(eventName), @(additionalInfo), NO, YES, nil);
}

DTX_ALWAYS_INLINE
static void __endEvent(DTXEventIdentifier eventId, NSDate* timestamp)
{
	if(eventId)
	{
		__DTXProfilerMarkEventIntervalEnd(timestamp, eventId, DTXEventStatusCompleted, nil);
	}
}

DTX_ALWAYS_INLINE
static NSString* getOptionalArgument(size_t numArgs, systrace_arg_t *args)
{
	if (numArgs == 0)
	{
		return @"";
	}
	NSMutableString* output = [[NSMutableString alloc] init];
	if (numArgs == 1)
	{
		[output appendFormat:@"%@", @(args[0].value)];
	}
	else
	{
		[output appendString:@"{ "];
		for (size_t i = 0; i < numArgs; i++)
		{
			[output appendFormat:@"%@: %@", @(args[i].key), @(args[i].value)];
			if (i < numArgs - 1)
			{
				[output appendString:@", "];
			}
		}
		[output appendString:@" }"];
	}
	return output;
}

static NSMutableDictionary<NSNumber*, DTXEventIdentifier>* asyncSections = nil;
static NSMutableDictionary<NSNumber*, DTXEventIdentifier>* asyncFlows = nil;

extern dispatch_queue_t __eventDispatchQueue;

static char* __DTXProfileStart()
{
	return NULL;
}

static void __DTXProfileStop(){}

static void __DTXProfileBeginSection(__unused uint64_t tag, const char *name, size_t numArgs, systrace_arg_t *args)
{
	NSDate* date = NSDate.date;
	NSThread* thread = NSThread.currentThread;
	dispatch_async(__eventDispatchQueue, ^{
		DTXEventIdentifier eventIdentifier = __startEvent(date, name, "Section",  [getOptionalArgument(numArgs, args) UTF8String]);
		NSMutableArray* sections = thread.threadDictionary[@"DTXSections"];
		if(sections == nil)
		{
			sections = [[NSMutableArray alloc] init];
			thread.threadDictionary[@"DTXSections"] = sections;
		}
		
		[sections addObject:eventIdentifier];
	});
}

static void __DTXProfileEndSection(__unused uint64_t tag, __unused size_t numArgs, __unused systrace_arg_t *args)
{
	NSDate* date = NSDate.date;
	NSThread* thread = NSThread.currentThread;
	dispatch_async(__eventDispatchQueue, ^{
		NSMutableArray* sections = thread.threadDictionary[@"DTXSections"];
		if(sections == nil || sections.count == 0)
		{
			return;
		}
		
		DTXEventIdentifier eventIdentifier = sections.lastObject;
		__endEvent(eventIdentifier, date);
		[sections removeLastObject];
	});
}

static void __DTXProfileBeginAsyncSection(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		asyncSections = [[NSMutableDictionary alloc] init];
	});
	
	NSDate* date = NSDate.date;
	dispatch_async(__eventDispatchQueue, ^{
		DTXEventIdentifier eventIdentifier = __startEvent(date, name, "AsyncSection",  [getOptionalArgument(numArgs, args) UTF8String]);
		[asyncSections setObject:eventIdentifier forKey:@(cookie)];
	});
}

static void __DTXProfileEndAsyncSection(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args)
{
	NSDate* currDate = NSDate.date;
	dispatch_async(__eventDispatchQueue, ^{
		NSNumber* key = @(cookie);
		DTXEventIdentifier eventIdentifier = asyncSections[key];
		if(eventIdentifier)
		{
			__endEvent(eventIdentifier, currDate);
			[asyncSections removeObjectForKey:key];
		}
	});
	
}

static void __DTXProfileInstantSection(uint64_t tag, const char *name, char scope)
{
	__DTXProfilerMarkEvent(NSDate.date,
						   @"InstantSection",
						   @(name),
						   DTXEventStatusCompleted,
						   nil);
}

static void __DTXProfileBeginAsyncFlow(uint64_t tag, const char *name, int cookie)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		asyncFlows = [[NSMutableDictionary alloc] init];
	});
	
	NSDate* date = NSDate.date;
	dispatch_async(__eventDispatchQueue, ^{
		DTXEventIdentifier eventId = __startEvent(date, name, "AsyncFlow", "");
		[asyncFlows setObject:eventId forKey:@(cookie)];
	});
}

static void __DTXProfileEndAsyncFlow(uint64_t tag, const char *name, int cookie)
{
	NSDate* date = NSDate.date;
	dispatch_async(__eventDispatchQueue, ^{
		NSNumber* key = @(cookie);
		DTXEventIdentifier eventId = asyncFlows[key];
		if (eventId)
		{
			__endEvent(eventId, date);
			[asyncFlows removeObjectForKey:key];
		}
	});
}

void DTXInstallRNJSProfilerHooks(JSContext* ctx)
{
	ctx[@"nativeTraceBeginSection"] = ^ (int tag, NSString* name , id args)
	{
		__DTXProfileBeginSection(tag, name.UTF8String, 0, NULL);
	};
	
	ctx[@"nativeTraceEndSection"] = ^ (int tag)
	{
		__DTXProfileEndSection(tag, 0, NULL);
	};
	
	ctx[@"nativeTraceBeginAsyncSection"] = ^(int tag, NSString* name, int cookie)
	{
		__DTXProfileBeginAsyncSection(tag, name.UTF8String, cookie, 0, NULL);
	};
	
	ctx[@"nativeTraceEndAsyncSection"] = ^(int tag, NSString* name, int cookie)
	{
		__DTXProfileEndAsyncSection(tag, name.UTF8String, cookie, 0, NULL);
	};
	
	
	ctx[@"nativeTraceBeginLegacy"] = ^()
	{
		//Ignored
	};
	
	ctx[@"nativeTraceEndLegacy"] = ^()
	{
		//Ignored
	};
}


static void (*__orig_RCTBridge_setUp)(id self, SEL _cmd);
static void __dtxinst_RCTBridge_setUp(id self, SEL _cmd)
{
	__orig_RCTBridge_setUp(self, _cmd);
	void (*RCTProfileInit)(id) = (void*)dlsym(RTLD_DEFAULT, "RCTProfileInit");
	//Can also call +[RCTBridge currentBridge], if batchedBridge is ever removed.
	RCTProfileInit([self valueForKey:@"batchedBridge"]);
}

void DTXRegisterRNProfilerCallbacks()
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		RCTProfileCallbacks wixProfileCallbacks =
		{
			__DTXProfileStart,
			__DTXProfileStop,
			__DTXProfileBeginSection,
			__DTXProfileEndSection,
			__DTXProfileBeginAsyncSection,
			__DTXProfileEndAsyncSection,
			__DTXProfileInstantSection,
			__DTXProfileBeginAsyncFlow,
			__DTXProfileEndAsyncFlow
		};
		
		void (*RCTProfileRegisterCallbacks)(RCTProfileCallbacks *) = dlsym(RTLD_DEFAULT, "RCTProfileRegisterCallbacks");
		if(RCTProfileRegisterCallbacks != NULL)
		{
			RCTProfileRegisterCallbacks(&wixProfileCallbacks);
		}
		
		Class cls = NSClassFromString(@"RCTBridge");
		Method m = class_getInstanceMethod(cls, NSSelectorFromString(@"setUp"));
		__orig_RCTBridge_setUp = (void*)method_getImplementation(m);
		method_setImplementation(m, (IMP)__dtxinst_RCTBridge_setUp);
	});
}
