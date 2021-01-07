//
//  DTXReactNativeProfilerSupport.m
//  DTXProfiler
//
//  Created by Muhammad Abed El Razek on 18/03/2019.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXReactNativeProfilerSupport.h"

@import ObjectiveC;
@import Darwin;
#import <Foundation/Foundation.h>
#import <DTXProfiler/DTXEvents.h>
#import "DTXProfilerAPI-Private.h"

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

@protocol RCTDevSettingsDataSource <NSObject>

/**
 * Updates the setting with the given key to the given value.
 * How the data source's state changes depends on the implementation.
 */
- (void)updateSettingWithValue:(id)value forKey:(NSString *)key;

/**
 * Returns the value for the setting with the given key.
 */
- (id)settingForKey:(NSString *)key;

@end

NSString* const __RCTProfilingEnabled = @"profilingEnabled";

#pragma Implementation

#pragma mark Helper Methods

DTX_ALWAYS_INLINE
static NSDictionary* __DTXGetArgumentsFromSystraceArgs(size_t args_count, systrace_arg_t* args)
{
	if(args_count == 0)
	{
		return nil;
	}
	
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	for (NSUInteger idx = 0; idx < args_count; idx++)
	{
		NSString* key = [[NSString alloc] initWithBytes:args[idx].key length:args[idx].key_len encoding:NSUTF8StringEncoding];
		NSString* value = [[NSString alloc] initWithBytes:args[idx].value length:args[idx].value_len encoding:NSUTF8StringEncoding];
		
		rv[key] = value;
		
//		[rv addObject:@{key: value}];
	}
	
	return rv;
}

static NSString* __DTXGetOptionalArgument(size_t numArgs, systrace_arg_t *args)
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

static char* __DTXProfileStart()
{
	return NULL;
}

static void __DTXProfileStop(){}

static void __DTXPreprocessRNName(NSString* rnName, uint64_t tag, NSArray* arguments, BOOL isFromJS, NSString** proposedCategory, NSString** proposedName, NSString** proposedMessage)
{
	if(isFromJS)
	{
		if([rnName hasPrefix:@"JS_require"])
		{
			NSString* moduleName = [rnName substringFromIndex:11];
			
			*proposedCategory = @"React Native (JS Require)";
			*proposedName = moduleName;
			*proposedMessage = [arguments description];
			
			return;
		}
	
		*proposedCategory = @"React Native (JS Lifecycle)";
	}
	else
	{
		*proposedCategory = @"React Native (Native Lifecycle)";
	}
	
	NSString* moduleName;
	if(arguments.count > 0 && (moduleName = [arguments valueForKeyPath:@"moduleClass"]) != nil && [moduleName isKindOfClass:NSNull.class] == NO)
	{
		*proposedCategory = @"React Native (Native Modules Setup)";
		*proposedName = moduleName;
		*proposedMessage = rnName;
		
		return;
	}
	
//	if(arguments.count > 0)
//	{
//		NSLog(@"🤦‍♂️ %@ %@ %@", rnName, @(tag), NSThread.currentThread);
//	}
	
	*proposedName = rnName;
	*proposedMessage = [arguments description];
}

static void __DTXProfileBeginSectionInner(__unused uint64_t tag, NSString* name, id arguments, BOOL isFromJS)
{
	NSDate* date = NSDate.date;
	NSThread* thread = NSThread.currentThread;
	
	NSString* eventCategory = @"React Native";
	NSString* eventName;
	NSString* eventMessage;
	
	__DTXPreprocessRNName(name, tag, arguments, isFromJS, &eventCategory, &eventName, &eventMessage);
	
	DTXEventIdentifier eventIdentifier = __DTXProfilerMarkEventIntervalBegin(date, eventCategory, eventName, eventMessage, _DTXEventTypeInternalRN, nil);
	NSMutableArray* sections = thread.threadDictionary[@"DTXSections"];
	if(sections == nil)
	{
		sections = [[NSMutableArray alloc] init];
		thread.threadDictionary[@"DTXSections"] = sections;
	}
	
	[sections addObject:eventIdentifier];
}

static void __DTXProfileBeginSection(__unused uint64_t tag, const char *name, size_t args_count, systrace_arg_t *args)
{
	__DTXProfileBeginSectionInner(tag, @(name), __DTXGetArgumentsFromSystraceArgs(args_count, args), NO);
}

static void __DTXProfileEndSection(__unused uint64_t tag, __unused size_t numArgs, __unused systrace_arg_t *args)
{
	NSDate* date = NSDate.date;
	NSThread* thread = NSThread.currentThread;
	NSMutableArray* sections = thread.threadDictionary[@"DTXSections"];
	if(sections == nil || sections.count == 0)
	{
		return;
	}
	
	DTXEventIdentifier eventIdentifier = sections.lastObject;
	
	if(eventIdentifier == nil)
	{
		return;
	}
	
	__DTXProfilerMarkEventIntervalEnd(date, eventIdentifier, DTXEventStatusCompleted, nil);
	[sections removeLastObject];
}

static void __DTXProfileBeginAsyncSectionInner(uint64_t tag, NSString* name, int cookie, id arguments, BOOL isFromJS)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		asyncSections = [[NSMutableDictionary alloc] init];
	});
	
	NSDate* date = NSDate.date;
	
	NSString* eventCategory = @"React Native";
	NSString* eventName;
	NSString* eventMessage;
	
	__DTXPreprocessRNName(name, tag, arguments, isFromJS, &eventCategory, &eventName, &eventMessage);
	
	DTXEventIdentifier eventIdentifier = __DTXProfilerMarkEventIntervalBegin(date, eventCategory, eventName, eventMessage, _DTXEventTypeInternalRN, nil);
	[asyncSections setObject:eventIdentifier forKey:@(cookie)];
}

static void __DTXProfileBeginAsyncSection(uint64_t tag, const char *name, int cookie, size_t args_count, systrace_arg_t *args)
{
	__DTXProfileBeginAsyncSectionInner(tag, @(name), cookie, __DTXGetArgumentsFromSystraceArgs(args_count, args), NO);
}

static void __DTXProfileEndAsyncSection(uint64_t tag, const char *name, int cookie, size_t numArgs, systrace_arg_t *args)
{
	NSDate* date = NSDate.date;
	NSNumber* key = @(cookie);
	DTXEventIdentifier eventIdentifier = asyncSections[key];
	if(eventIdentifier == nil)
	{
		return;
	}
	
	__DTXProfilerMarkEventIntervalEnd(date, eventIdentifier, DTXEventStatusCompleted, nil);
	[asyncSections removeObjectForKey:key];
}

static void __DTXProfileInstantSection(uint64_t tag, const char *name, char scope)
{
//	__DTXProfilerMarkEvent(NSDate.date,
//						   @"React Native",
//						   @(name),
//						   DTXEventStatusCompleted,
//						   nil);
}

static void __DTXProfileBeginAsyncFlow(uint64_t tag, const char *name, int cookie)
{
//	static dispatch_once_t onceToken;
//	dispatch_once(&onceToken, ^{
//		asyncFlows = [[NSMutableDictionary alloc] init];
//	});
//
//	NSDate* date = NSDate.date;
//	DTXEventIdentifier eventId = __beginInterval(date, name, "AsyncFlow", "");
//	[asyncFlows setObject:eventId forKey:@(cookie)];
}

static void __DTXProfileEndAsyncFlow(uint64_t tag, const char *name, int cookie)
{
//	NSDate* date = NSDate.date;
//	NSNumber* key = @(cookie);
//	DTXEventIdentifier eventId = asyncFlows[key];
//	if (eventId)
//	{
//		__endInterval(eventId, date);
//		[asyncFlows removeObjectForKey:key];
//	}
}

void DTXInstallRNJSProfilerHooks(JSContext* ctx)
{
	ctx[@"nativeTraceBeginSection"] = ^ (int tag, NSString* name , id args)
	{
		__DTXProfileBeginSectionInner(tag, name, args, YES);
	};
	
	ctx[@"nativeTraceEndSection"] = ^ (int tag)
	{
		__DTXProfileEndSection(tag, 0, NULL);
	};
	
	ctx[@"nativeTraceBeginAsyncSection"] = ^(int tag, NSString* name, int cookie)
	{
		__DTXProfileBeginAsyncSectionInner(tag, name, cookie, nil, YES);
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

//Workaround for
//	https://github.com/wix/DetoxInstruments/issues/44
//	https://github.com/facebook/react-native/issues/24952
@interface NSObject ()

@property (nonatomic, readonly) id uiManager;
- (id)viewForReactTag:(id)arg1;

@end

static void __dtx_RCTProfileUnhookInstance(id instance)
{
	if ([instance class] != object_getClass(instance)) {
		object_setClass(instance, [instance class]);
	}
}

static id __activeBridge;
static BOOL __bridgeShouldProfile;
static NSUInteger __activeListeningProfilers;
static pthread_mutex_t __activeListeningProfilersMutex;

BOOL (*__RCTProfileIsProfiling)(void);
static void (*__RCTProfileInit)(id);
static void (*__RCTProfileEnd)(id bridge, void (^callback)(NSString *));

static void (*__orig_RCTBridge_setUp)(id self, SEL _cmd);
static void __dtxinst_RCTBridge_setUp(id self, SEL _cmd)
{
	__orig_RCTBridge_setUp(self, _cmd);
	//Can also call +[RCTBridge currentBridge], if batchedBridge is ever removed.
	
	pthread_mutex_lock(&__activeListeningProfilersMutex);
	id oldActiveBridge = __activeBridge;
	__activeBridge = [self valueForKey:@"batchedBridge"];
	
	if(oldActiveBridge != nil)
	{
		for (id view in [[oldActiveBridge uiManager] valueForKey:@"viewRegistry"]) {
			__dtx_RCTProfileUnhookInstance([[oldActiveBridge uiManager] viewForReactTag:view]);
		}
	}
	
	if(__activeListeningProfilers > 0)
	{
		__RCTProfileInit(__activeBridge);
	}
	pthread_mutex_unlock(&__activeListeningProfilersMutex);
}

static id (*__orig_RCTDevSettings_initWithDataSource)(id self, SEL _cmd, id<RCTDevSettingsDataSource> dataSource);
static id __dtxinst_RCTDevSettings_initWithDataSource(id self, SEL _cmd, id<RCTDevSettingsDataSource> dataSource)
{
	pthread_mutex_lock(&__activeListeningProfilersMutex);
	[dataSource updateSettingWithValue:@(__bridgeShouldProfile) forKey:__RCTProfilingEnabled];
	pthread_mutex_unlock(&__activeListeningProfilersMutex);
	return __orig_RCTDevSettings_initWithDataSource(self, _cmd, dataSource);
}

static void __DTXDidAddProfiler(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo)
{
	DTXProfiler* profiler = NS(object);
	if(profiler.profilingConfiguration.recordInternalReactNativeActivity == YES)
	{
		pthread_mutex_lock(&__activeListeningProfilersMutex);
		__activeListeningProfilers += 1;
		__bridgeShouldProfile = YES;
		if(__activeListeningProfilers == 1 && __activeBridge != nil)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				__RCTProfileInit(__activeBridge);
			});
		}
		pthread_mutex_unlock(&__activeListeningProfilersMutex);
	}
}

static void __DTXDidRemoveProfiler(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo)
{
	DTXProfiler* profiler = NS(object);
	if(profiler.profilingConfiguration.recordInternalReactNativeActivity == YES)
	{
		pthread_mutex_lock(&__activeListeningProfilersMutex);
		__activeListeningProfilers -= 1;
		if(__activeListeningProfilers == 0)
		{
			__bridgeShouldProfile = NO;
			
			if(__activeBridge != nil)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					__RCTProfileEnd(__activeBridge, ^ (NSString* string) {} );
					id devSettings = [__activeBridge valueForKey:@"devSettings"];
					[devSettings setValue:@NO forKey:__RCTProfilingEnabled];
				});
			}
		}
		pthread_mutex_unlock(&__activeListeningProfilersMutex);
	}
}

void DTXRegisterRNProfilerCallbacks()
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		void (*RCTProfileRegisterCallbacks)(RCTProfileCallbacks *) = dlsym(RTLD_DEFAULT, "RCTProfileRegisterCallbacks");
		
		if(RCTProfileRegisterCallbacks == NULL)
		{
			return;
		}
		
		static RCTProfileCallbacks callbacks =
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
		RCTProfileRegisterCallbacks(&callbacks);
		
		__RCTProfileIsProfiling = (void*)dlsym(RTLD_DEFAULT, "RCTProfileIsProfiling");
		__RCTProfileInit = (void*)dlsym(RTLD_DEFAULT, "RCTProfileInit");
		__RCTProfileEnd = (void*)dlsym(RTLD_DEFAULT, "RCTProfileEnd");
		
		if(__RCTProfileIsProfiling == NULL || __RCTProfileInit == NULL || __RCTProfileEnd == NULL)
		{
			return;
		}
		
		Class cls = NSClassFromString(@"RCTBridge");
		
		if(cls == nil)
		{
			return;
		}
		
		Method m = class_getInstanceMethod(cls, NSSelectorFromString(@"setUp"));
		
		if(m == NULL)
		{
			return;
		}
		
		__orig_RCTBridge_setUp = (void*)method_getImplementation(m);
		method_setImplementation(m, (IMP)__dtxinst_RCTBridge_setUp);
		
		cls = NSClassFromString(@"RCTDevSettings");
		
		if(cls == nil)
		{
			return;
		}
		
		m = class_getInstanceMethod(cls, NSSelectorFromString(@"initWithDataSource:"));
		
		if(m == NULL)
		{
			return;
		}
		
		__orig_RCTDevSettings_initWithDataSource = (void*)method_getImplementation(m);
		method_setImplementation(m, (IMP)__dtxinst_RCTDevSettings_initWithDataSource);
		
		pthread_mutex_init(&__activeListeningProfilersMutex, NULL);
		__activeBridge = nil;
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, __DTXDidAddProfiler, CF(__DTXDidAddActiveProfilerNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, __DTXDidRemoveProfiler, CF(__DTXDidRemoveActiveProfilerNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
		
		//Iterate existing profilers and call the notification callback for them.
		__DTXProfilerEnumerateActiveProfilersWithBlock(^(DTXProfiler *profiler) {
			__DTXDidAddProfiler(nil, nil, CF(__DTXDidAddActiveProfilerNotification), CF(profiler), nil);
		});
	});
}
