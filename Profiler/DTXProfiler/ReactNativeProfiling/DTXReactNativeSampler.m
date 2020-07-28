//
//  DTXReactNativeSampler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXReactNativeSampler.h"
#import <stdatomic.h>
#import "fishhook.h"
#import "DTXRNJSCSourceMapsSupport.h"
#import "DTXLoggingRecorder.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "DTXProfilerAPI-Private.h"
#import "DTXReactNativeProfilerSupport.h"

@import ObjectiveC;
@import Darwin;
@import UIKit;

static atomic_uintmax_t __bridgeNToJSCallCount = 0;
static atomic_uintmax_t __bridgeJSToNCallCount = 0;
static atomic_uintmax_t __bridgeNToJSDataSize = 0;
static atomic_uintmax_t __bridgeJSToNDataSize = 0;

static atomic_thread __rnThread = MACH_PORT_NULL;

static JSContextRef __rnCtx;

//static dispatch_semaphore_t __rnBacktraceSem;
//static NSString* __rnLastBacktrace;

dispatch_queue_t __eventDispatchQueue;

static NSMutableDictionary<NSString*, NSString*>* __rn_valuePropertyMapping;

//__unused static void DTXJSCStackTraceSignalHandler(int signr, siginfo_t *info, void *secret)
//{
//	const char* bt = JSContextCreateBacktrace_unsafe(__rnCtx, UINT_MAX);
//	if(bt == NULL)
//	{
//		__rnLastBacktrace = @"";
//	}
//	else
//	{
//		__rnLastBacktrace = [NSString stringWithUTF8String:bt];
//	}
//
//	dispatch_semaphore_signal(__rnBacktraceSem);
//}

static void installDTXNativeLoggingHook(JSContext* ctx)
{
	ctx[@"dtxNativeLoggingHook"] = ^ {
		NSMutableArray *objects = [NSMutableArray new];
		NSArray *logArgs = ((JSValue *)[JSContext currentArguments].firstObject).toArray;
		NSString *logLine = ((JSValue *)[JSContext currentArguments].lastObject).toString;
		for (id object in logArgs) {
			if([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]])
			{
				[objects addObject:object];
			}
		}
		DTXProfilerAddLogLineWithObjects([logLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]], objects);
	};
}

static
DTX_ALWAYS_INLINE
void __insertEventFromJS(NSDictionary<NSString*, id>* sample, BOOL allowJSTimers, BOOL useNativeTimestamp, uint64_t threadIdentifier)
{
	NSString* identifier = sample[@"identifier"];
	NSUInteger type = [sample[@"type"] unsignedIntegerValue];
	NSDate* timestamp = useNativeTimestamp ? [NSDate date] : [NSDate dateWithTimeIntervalSince1970:[sample[@"timestamp"] doubleValue] / 1000];
	NSDictionary<NSString*, id>* params = sample[@"params"];
	BOOL isFromTimer = [sample[@"isFromJSTimer"] boolValue];
	
	if(isFromTimer == YES && allowJSTimers == NO)
	{
		return;
	}
	
	switch (type) {
		case 0:
		{
			id additionalInfo = params[@"2"];
			if(additionalInfo == NS(kCFNull))
			{
				additionalInfo = nil;
			}
			__DTXProfilerMarkEventIntervalBeginIdentifierThreadIdentifier(identifier, threadIdentifier, timestamp, params[@"0"], params[@"1"], additionalInfo, [params[@"3"] boolValue] ? _DTXEventTypeJSTimer : _DTXEventTypeSignpost, [params[@"4"] componentsSeparatedByString:@"\n"]);
		}	break;
		case 1:
		{
			id additionalInfo = params[@"1"];
			if(additionalInfo == NS(kCFNull))
			{
				additionalInfo = nil;
			}
			__DTXProfilerMarkEventIntervalEndThreadIdentifier(threadIdentifier, timestamp, identifier, [params[@"0"] intValue], additionalInfo);
		}	break;
		case 10:
		{
			id additionalInfo = params[@"3"];
			if(additionalInfo == NS(kCFNull))
			{
				additionalInfo = nil;
			}
			__DTXProfilerMarkEventIdentifierThreadIdentifier(identifier, threadIdentifier, timestamp, params[@"0"], params[@"1"], [params[@"2"] intValue], additionalInfo, _DTXEventTypeSignpost);
		}	break;
		default:
			break;
	}
}

static void installDTXSignpostHook(JSContext* ctx)
{
	ctx[@"__dtx_getEventsSettings_v1"] = ^ NSDictionary* () {
		return @{@"captureTimers": @YES};
	};
	
	ctx[@"__dtx_markEventBatch_v1"] = ^ (NSArray<NSDictionary<NSString*, id>*>* samples)
	{
		uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
		dispatch_async(__eventDispatchQueue, ^{
			DTXProfilingConfiguration* config = __DTXProfilerGetActiveConfiguration();
			BOOL allowJSTimers = config.recordReactNativeTimersAsActivity;
			
			for(NSDictionary<NSString*, id>* sample in samples)
			{
				__insertEventFromJS(sample, allowJSTimers, NO, threadIdentifier);
			}
		});
	};
	
	ctx[@"__dtx_markEvent_v2"] = ^ (NSDictionary<NSString*, id>* sample)
	{
		uint64_t threadIdentifier = _DTXThreadIdentifierForCurrentThread();
		dispatch_async(__eventDispatchQueue, ^{
			DTXProfilingConfiguration* config = __DTXProfilerGetActiveConfiguration();
			BOOL allowJSTimers = config.recordReactNativeTimersAsActivity;
			
			__insertEventFromJS(sample, allowJSTimers, YES, threadIdentifier);
		});
	};
}

static void (*orig_runRunLoopThread)(id, SEL) = NULL;
static void swz_runRunLoopThread(id self, SEL _cmd)
{
	atomic_store(&__rnThread, mach_thread_self());
	
	orig_runRunLoopThread(self, _cmd);
}

//static NSString* DTXJSValueGeneringToNSString(JSContextRef ctx, JSValueRef value)
//{
//	NSString* rv = nil;
//	
//	JSValueRef exception = NULL;
//	JSStringRef jsonStrRef = JSValueToStringCopy(ctx, value, &exception);
//	
//	if(exception == NULL && jsonStrRef != NULL)
//	{
//		rv = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, jsonStrRef);
//	}
//	
//	if(jsonStrRef != NULL)
//	{
//		JSStringRelease(jsonStrRef);
//	}
//	
//	return rv;
//}

static NSString* DTXJSValueJSONStringToNSString(JSContextRef ctx, JSValueRef value)
{
	NSString* rv = nil;
	
	JSValueRef exception = NULL;
	
	__block JSStringRef strRef = NULL;
	dtx_defer {
		if(strRef != NULL)
		{
			JSStringRelease(strRef);
		}
	};
	
	if(JSValueIsString(ctx, value))
	{
		strRef = JSValueToStringCopy(ctx, value, &exception);
	}
	else
	{
		strRef = JSValueCreateJSONString(ctx, value, 0, &exception);
	}
	
	if(exception == NULL && strRef != NULL)
	{
		rv = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, strRef);
	}
	
	return rv;
}

static void __dtx_addRNBridgeDataCapture(JSContextRef ctx, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef rv, JSValueRef* exception, BOOL isFromNative)
{
	NSString* funcName = __rn_valuePropertyMapping[[NSString stringWithFormat:@"%p", object]];
	
	atomic_fetch_add(&__bridgeNToJSCallCount, 1);
	
	NSMutableArray* args = [NSMutableArray new];
	
	for(size_t i = 0; i < argumentCount; i++)
	{
		NSString* str = DTXJSValueJSONStringToNSString(ctx, arguments[i]);
		
		if(str == nil)
		{
			continue;
		}
		
		atomic_fetch_add(&__bridgeNToJSDataSize, str.length);
		[args addObject:str];
	}
	
	NSString* exc;
	NSString* rvStr;
	
//	if(*exception == NULL || exception == NULL)
//	{
		rvStr = DTXJSValueJSONStringToNSString(ctx, rv);
		atomic_fetch_add(&__bridgeNToJSDataSize, rvStr.length);
//	}
//	else
//	{
//		exc = DTXJSValueGeneringToNSString(ctx, *exception);
//	}
	
	__DTXProfilerAddRNBridgeDataCapture(funcName, args, rvStr, exc, isFromNative);
}

static JSValueRef (*__orig_JSObjectCallAsFunction)(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
static JSValueRef __dtx_JSObjectCallAsFunction(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	JSValueRef rv = __orig_JSObjectCallAsFunction(ctx, object, thisObject, argumentCount, arguments, exception);
	
	__dtx_addRNBridgeDataCapture(ctx, object, argumentCount, arguments, rv, exception, YES);
	
	return rv;
}

//static JSObjectRef __dtx_JSObjectMakeFunctionWithCallbackWrapper(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction, JSValueRef functionValue)
//{
//	if(name != NULL)
//	{
//
//	}
//
//	return __orig_JSObjectMakeFunctionWithCallback(ctx, name, callAsFunction);
//}

static thread_local BOOL __dtx_isInRNInitialize = NO;
static JSObjectInitializeCallback __rn_initialize;
static void __dtx_initialize(JSContextRef ctx, JSObjectRef object)
{
	__dtx_isInRNInitialize = YES;
	
	if(__rnCtx == nil || __rnCtx != ctx)
	{
		JSContext* objcCtx = [JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)ctx];
		installDTXNativeLoggingHook(objcCtx);
		installDTXSignpostHook(objcCtx);
		DTXInstallRNJSProfilerHooks(objcCtx);
	}
	
	__rnCtx = ctx;
	
	__rn_initialize(ctx, object);
	
	__dtx_isInRNInitialize = NO;
}

static JSObjectFinalizeCallback __rn_finalize;
static void __dtx_finalize(JSObjectRef object)
{
	__rn_finalize(object);
}

static JSObjectCallAsFunctionCallback __rn_callAsFunction;
static JSValueRef __dtx_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	JSValueRef rvRef = __rn_callAsFunction(ctx, function, thisObject, argumentCount, arguments, exception);
	
	__dtx_addRNBridgeDataCapture(ctx, function, argumentCount, arguments, rvRef, exception, NO);
	
	return rvRef;
}

static JSClassRef (*__orig_JSClassCreate)(const JSClassDefinition *definition);
static JSClassRef __dtx_JSClassCreate(const JSClassDefinition *definition)
{
	const JSClassDefinition* definitionToUse = definition;
	__block JSClassDefinition* newDef = NULL;
	dtx_defer {
		if(newDef != NULL)
		{
			free(newDef);
		}
	};
	
	if(definition->callAsFunction != NULL)
	{
		newDef = malloc(sizeof(JSClassDefinition));
		memcpy(newDef, definition, sizeof(JSClassDefinition));
		__rn_initialize = newDef->initialize;
		newDef->initialize = __dtx_initialize;
		__rn_finalize = newDef->finalize;
		newDef->finalize = __dtx_finalize;
		__rn_callAsFunction = newDef->callAsFunction;
		newDef->callAsFunction = __dtx_callAsFunction;
		definitionToUse = newDef;
	}
	
	return __orig_JSClassCreate(definitionToUse);
}

static void (*__orig_JSObjectSetProperty)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef* exception);
static void __dtx_JSObjectSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef* exception)
{
	NSString* pName = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyName);
	if([pName isEqualToString:@"name"])
	{
		__block JSStringRef strValue = JSValueToStringCopy(ctx, value, NULL);
		dtx_defer {
			JSStringRelease(strValue);
		};
		
		__rn_valuePropertyMapping[[NSString stringWithFormat:@"%p", object]] = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, strValue);
	}
	
	//Normal path
	__orig_JSObjectSetProperty(ctx, object, propertyName, value, attributes, exception);
}

static double __rnCPUUsage(thread_t safeRNThread)
{
	thread_info_data_t threadInfo;
	
	mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
	if (thread_info(safeRNThread, THREAD_BASIC_INFO, (thread_info_t)threadInfo, &threadInfoCount) != KERN_SUCCESS)
	{
		return 0;
	}
	
	thread_basic_info_t threadBasicInfo = (thread_basic_info_t)threadInfo;
	
	return threadBasicInfo->cpu_usage / (double)TH_USAGE_SCALE;
}

static int (*__orig_UIApplication_run)(id self, SEL _cmd);
static int __dtxinst_UIApplication_run(id self, SEL _cmd)
{
	if(DTXReactNativeSampler.isReactNativeInstalled)
	{
		//Modern RN
		Class cls = NSClassFromString(@"RCTCxxBridge");
		
		Method m = class_getClassMethod(cls, NSSelectorFromString(@"runRunLoop"));
		if(m == NULL)
		{
			m = class_getInstanceMethod(cls, NSSelectorFromString(@"runJSRunLoop"));
		}
		
		if(m != NULL)
		{
			orig_runRunLoopThread = (void(*)(id, SEL))method_getImplementation(m);
			method_setImplementation(m, (IMP)swz_runRunLoopThread);
		}
		
		DTXRegisterRNProfilerCallbacks();
	}
	
	return __orig_UIApplication_run(self, _cmd);
}

__attribute__((constructor))
static void __DTXInitializeRNSampler()
{
//	__rnBacktraceSem = dispatch_semaphore_create(0);
	
	__rn_valuePropertyMapping = [NSMutableDictionary new];
	
	__orig_JSObjectCallAsFunction = JSObjectCallAsFunction;
	__orig_JSClassCreate = JSClassCreate;
	__orig_JSObjectSetProperty = JSObjectSetProperty;
	
	rebind_symbols((struct rebinding[]){
		{"JSObjectCallAsFunction",
			__dtx_JSObjectCallAsFunction,
			NULL
		},
		{
			"JSClassCreate",
			__dtx_JSClassCreate,
			NULL
		},
		{
			"JSObjectSetProperty",
			__dtx_JSObjectSetProperty,
			NULL
		},
	}, 3);
	
	Method m = class_getInstanceMethod(UIApplication.class, NSSelectorFromString(@"_run"));
	__orig_UIApplication_run = (void*)method_getImplementation(m);
	method_setImplementation(m, (void*)__dtxinst_UIApplication_run);
	
//	struct sigaction sa;
//	sigfillset(&sa.sa_mask);
//	sa.sa_flags = SA_SIGINFO;
//	sa.sa_sigaction = DTXJSCStackTraceSignalHandler;
//	sigaction(SIGCHLD, &sa, NULL);
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
	__eventDispatchQueue = dtx_dispatch_queue_create_autoreleasing("com.wix.DTXRNSampler-Events", qosAttribute);
}

@implementation DTXReactNativeSampler
{
	uint64_t _initialBridgeNToJSCallCount;
	uint64_t _initialBridgeJSToNCallCount;
	uint64_t _initialBridgeNToJSDataSize;
	uint64_t _initialBridgeJSToNDataSize;
	
	uint64_t _prevBridgeNToJSCallCount;
	uint64_t _prevBridgeJSToNCallCount;
	uint64_t _prevBridgeNToJSDataSize;
	uint64_t _prevBridgeJSToNDataSize;
	
	BOOL _shouldSampleThread;
	BOOL _shouldSymbolicate;
}

+ (BOOL)isReactNativeInstalled
{
	return NSClassFromString(@"RCTBridge") != nil;
}

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	self = [super init];
	
	if(self)
	{
		uint64_t bridgeNToJSDataSize = atomic_load(&__bridgeNToJSDataSize);
		uint64_t bridgeJSToNDataSize = atomic_load(&__bridgeJSToNDataSize);
		uint64_t bridgeNToJSCallCount = atomic_load(&__bridgeNToJSCallCount);
		uint64_t bridgeJSToNCallCount = atomic_load(&__bridgeJSToNCallCount);
		
		_initialBridgeNToJSCallCount = bridgeNToJSCallCount;
		_initialBridgeJSToNCallCount = bridgeJSToNCallCount;
		_initialBridgeNToJSDataSize = bridgeNToJSDataSize;
		_initialBridgeJSToNDataSize = bridgeJSToNDataSize;
		
//		BOOL didLoadCustomJSCWrapper = DTXLoadJSCWrapper(NULL);
		
//		_shouldSampleThread = didLoadCustomJSCWrapper && configuration.collectJavaScriptStackTraces;
//		_shouldSymbolicate = didLoadCustomJSCWrapper && configuration.symbolicateJavaScriptStackTraces;
	}
	
	return self;
}

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	uint64_t bridgeNToJSCallCount = atomic_load(&__bridgeNToJSCallCount) - _initialBridgeNToJSCallCount;
	uint64_t bridgeJSToNCallCount = atomic_load(&__bridgeJSToNCallCount) - _initialBridgeJSToNCallCount;
	uint64_t bridgeNToJSDataSize = atomic_load(&__bridgeNToJSDataSize) - _initialBridgeNToJSDataSize;
	uint64_t bridgeJSToNDataSize = atomic_load(&__bridgeJSToNDataSize) - _initialBridgeJSToNDataSize;
	
	_bridgeNToJSCallCount = bridgeNToJSCallCount;
	_bridgeJSToNCallCount = bridgeJSToNCallCount;
	_bridgeNToJSDataSize = bridgeNToJSDataSize;
	_bridgeJSToNDataSize = bridgeJSToNDataSize;
	
	_bridgeNToJSCallCountDelta = bridgeNToJSCallCount - _prevBridgeNToJSCallCount;
	_bridgeJSToNCallCountDelta = bridgeJSToNCallCount - _prevBridgeJSToNCallCount;
	_bridgeNToJSDataSizeDelta = bridgeNToJSDataSize - _prevBridgeNToJSDataSize;
	_bridgeJSToNDataSizeDelta = bridgeJSToNDataSize - _prevBridgeJSToNDataSize;
	
	_prevBridgeNToJSCallCount = bridgeNToJSCallCount;
	_prevBridgeJSToNCallCount = bridgeJSToNCallCount;
	_prevBridgeNToJSDataSize = bridgeNToJSDataSize;
	_prevBridgeJSToNDataSize = bridgeJSToNDataSize;
	
	thread_t safeRNThread = atomic_load(&__rnThread);
	
	if(safeRNThread == MACH_PORT_NULL)
	{
		_cpu = 0.0;
		_currentStackTrace = @"";
		
		return;
	}
	
//	if(_shouldSampleThread)
//	{
//		pthread_kill(pthread_from_mach_thread_np(safeRNThread), SIGCHLD);
//		dispatch_semaphore_wait(__rnBacktraceSem, DISPATCH_TIME_FOREVER);
//		
//		_currentStackTrace = __rnLastBacktrace;
//		
//		if(thread_suspend(safeRNThread) == KERN_SUCCESS)
//		{
//			const char* bt = JSContextCreateBacktrace_unsafe(__rnCtx, UINT_MAX);
//			_currentStackTrace = [NSString stringWithUTF8String:bt];
//			thread_resume(safeRNThread);
//		}
//		else
//		{
//			//Thread is already invalid, no stack trace.
//			_currentStackTrace = @"";
//		}
//		
//		_currentStackTraceSymbolicated = NO;
//	}
	
	_cpu = __rnCPUUsage(safeRNThread);
}
@end
