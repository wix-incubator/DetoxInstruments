//
//  DTXReactNativeSampler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXReactNativeSampler.h"
#import <stdatomic.h>
#import "fishhook.h"
#import "DTXRNJSCSourceMapsSupport.h"
#import "DTXLoggingRecorder.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "DTXCustomJSCSupport.h"
#import "DTXProfiler-Private.h"
@import ObjectiveC;
@import Darwin;
@import UIKit;

static DTXJSCWrapper __jscWrapper;

static atomic_uintmax_t __bridgeNToJSDataSize = 0;
static atomic_uintmax_t __bridgeNToJSCallCount = 0;
static atomic_uintmax_t __bridgeJSToNDataSize = 0;
static atomic_uintmax_t __bridgeJSToNCallCount = 0;

static _Atomic thread_t __rnThread = MACH_PORT_NULL;

static JSContextRef __rnCtx;

static dispatch_semaphore_t __rnBacktraceSem;
static NSString* __rnLastBacktrace;

static dispatch_queue_t __eventDispatchQueue;

static NSMutableDictionary<NSString*, NSString*>* __JSValuePropertyMapping;

static void resetAtomicVars()
{
	atomic_store(&__bridgeJSToNCallCount, 0);
	atomic_store(&__bridgeNToJSDataSize, 0);
	atomic_store(&__bridgeNToJSCallCount, 0);
	atomic_store(&__bridgeJSToNDataSize, 0);
}

static void DTXJSCStackTraceSignalHandler(int signr, siginfo_t *info, void *secret)
{
	const char* bt = __jscWrapper.JSContextCreateBacktrace_unsafe(__rnCtx, UINT_MAX);
	if(bt == NULL)
	{
		__rnLastBacktrace = @"";
	}
	else
	{
		__rnLastBacktrace = [NSString stringWithUTF8String:bt];
	}
	
	dispatch_semaphore_signal(__rnBacktraceSem);
}

static void installDTXNativeLoggingHook(JSContext* ctx)
{
	ctx[@"dtxNativeLoggingHook"] = ^ {
		NSMutableArray *objects = [NSMutableArray new];
		NSArray *logArgs = ((JSValue *)[__jscWrapper.JSContext currentArguments].firstObject).toArray;
		NSString *logLine = ((JSValue *)[__jscWrapper.JSContext currentArguments].lastObject).toString;
		for (id object in logArgs) {
			if([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]])
			{
				[objects addObject:object];
			}
		}
		
		DTXProfilerAddLogLineWithObjects([logLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]], objects);
	};
}

DTX_ALWAYS_INLINE
inline static void __insertEventFromJS(NSDictionary<NSString*, id>* sample, BOOL allowJSTimers, BOOL useNativeTimestamp)
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
	
	NSDate* date = NSDate.date;
	NSTimeInterval ti = CACurrentMediaTime() * 1000;
	
	NSLog(@"%.25f %.25f %.25f", date.timeIntervalSinceReferenceDate, date.timeIntervalSince1970, ti);
	
	switch (type) {
		case 0:
		{
			id additionalInfo = params[@"2"];
			if(additionalInfo == NS(kCFNull))
			{
				additionalInfo = nil;
			}
			__DTXProfilerMarkEventIntervalBeginIdentifier(identifier, timestamp, params[@"0"], params[@"1"], additionalInfo, [params[@"3"] boolValue], [params[@"4"] componentsSeparatedByString:@"\n"]);
		}	break;
		case 1:
		{
			id additionalInfo = params[@"1"];
			if(additionalInfo == NS(kCFNull))
			{
				additionalInfo = nil;
			}
			__DTXProfilerMarkEventIntervalEnd(timestamp, identifier, [params[@"0"] unsignedIntegerValue], additionalInfo);
		}	break;
		case 10:
		{
			id additionalInfo = params[@"3"];
			if(additionalInfo == NS(kCFNull))
			{
				additionalInfo = nil;
			}
			__DTXProfilerMarkEventIdentifier(identifier, timestamp, params[@"0"], params[@"1"], [params[@"2"] unsignedIntegerValue], additionalInfo);
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
		dispatch_async(__eventDispatchQueue, ^{
			DTXProfilingConfiguration* config = __DTXProfilerGetActiveConfiguration();
			BOOL allowJSTimers = config.recordReactNativeTimersAsEvents;
			
			for(NSDictionary<NSString*, id>* sample in samples)
			{
				__insertEventFromJS(sample, allowJSTimers, NO);
			}
		});
	};
	
	ctx[@"__dtx_markEvent_v2"] = ^ (NSDictionary<NSString*, id>* sample)
	{
		dispatch_async(__eventDispatchQueue, ^{
			DTXProfilingConfiguration* config = __DTXProfilerGetActiveConfiguration();
			BOOL allowJSTimers = config.recordReactNativeTimersAsEvents;
			
			__insertEventFromJS(sample, allowJSTimers, YES);
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
//	JSStringRef jsonStrRef = __jscWrapper.JSValueToStringCopy(ctx, value, &exception);
//	
//	if(exception == NULL && jsonStrRef != NULL)
//	{
//		rv = (__bridge_transfer NSString*)__jscWrapper.JSStringCopyCFString(kCFAllocatorDefault, jsonStrRef);
//	}
//	
//	if(jsonStrRef != NULL)
//	{
//		__jscWrapper.JSStringRelease(jsonStrRef);
//	}
//	
//	return rv;
//}

static NSString* DTXJSValueJSONStringToNSString(JSContextRef ctx, JSValueRef value)
{
	NSString* rv = nil;
	
	JSValueRef exception = NULL;
	JSStringRef jsonStrRef = __jscWrapper.JSValueCreateJSONString(ctx, value, 0, &exception);
	
	if(exception == NULL && jsonStrRef != NULL)
	{
		rv = (__bridge_transfer NSString*)__jscWrapper.JSStringCopyCFString(kCFAllocatorDefault, jsonStrRef);
	}
	
	if(jsonStrRef != NULL)
	{
		__jscWrapper.JSStringRelease(jsonStrRef);
	}
	
	return rv;
}

static JSValueRef (*__orig_JSObjectCallAsFunction)(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
static JSValueRef __dtx_JSObjectCallAsFunction(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	NSString* funcName = __JSValuePropertyMapping[[NSString stringWithFormat:@"%p", object]];
	
	atomic_fetch_add(&__bridgeNToJSCallCount, 1);
	
	NSMutableArray* args = [NSMutableArray new];
	
	for(size_t i = 0; i < argumentCount; i++)
	{
		NSString* str = DTXJSValueJSONStringToNSString(ctx, arguments[i]);
		atomic_fetch_add(&__bridgeNToJSDataSize, str.length);
		[args addObject:str];
	}
	
	NSString* exc;
	NSString* rvStr;
	
	JSValueRef rv = __orig_JSObjectCallAsFunction(ctx, object, thisObject, argumentCount, arguments, exception);
	
//	if(*exception == NULL)
//	{
		rvStr = DTXJSValueJSONStringToNSString(ctx, rv);
		atomic_fetch_add(&__bridgeNToJSCallCount, rvStr.length);
//	}
//	else
//	{
//		exc = DTXJSValueGeneringToNSString(ctx, *exception);
//	}
	
	__DTXProfilerAddRNBridgeDataCapture(funcName, args, rvStr, exc, YES);
	
	return rv;
}

static JSObjectRef (*__orig_JSObjectMakeFunctionWithCallback)(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction);
static JSObjectRef __dtx_JSObjectMakeFunctionWithCallback(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction)
{
	if(name != NULL)
	{
		JSContext* objcCtx = [__jscWrapper.JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)ctx];
		
		if(__rnCtx == nil || __rnCtx != ctx)
		{
			resetAtomicVars();
			installDTXNativeLoggingHook(objcCtx);
			installDTXSignpostHook(objcCtx);
		}
		
		__rnCtx = ctx;
		
		NSString* str = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, name);
		
		objcCtx[str] = ^ {
			atomic_fetch_add(&__bridgeJSToNCallCount, 1);

			JSValueRef* arguments = malloc(sizeof(JSValueRef) * [__jscWrapper.JSContext currentArguments].count);
			
			NSMutableArray* args = [NSMutableArray new];

			NSUInteger idx = 0;
			for(JSValue* obj in [__jscWrapper.JSContext currentArguments])
			{
				NSString* str = DTXJSValueJSONStringToNSString(ctx, [obj JSValueRef]);
				atomic_fetch_add(&__bridgeJSToNDataSize, str.length);
				
				[args addObject:str];
				
				arguments[idx] = [obj JSValueRef];
				
				idx += 1;
			}

			NSString* rvStr;
			NSString* exc;
			
			JSValueRef exception = NULL;

			JSValueRef rvRef = callAsFunction(ctx, __jscWrapper.JSValueToObject(ctx, [__jscWrapper.JSContext currentCallee].JSValueRef, NULL), __jscWrapper.JSValueToObject(ctx, [__jscWrapper.JSContext currentThis].JSValueRef, NULL), [__jscWrapper.JSContext currentArguments].count, arguments, &exception);

//			if(exception)
//			{
//				exc = DTXJSValueGeneringToNSString(ctx, exception);
//
//				JSValue* exceptionValue = [__jscWrapper.JSValue valueWithJSValueRef:exception inContext:[__jscWrapper.JSContext currentContext]];
//				[__jscWrapper.JSContext currentContext].exception = exceptionValue;
//			}
//			else
//			{
				rvStr = DTXJSValueJSONStringToNSString(ctx, rvRef);
				atomic_fetch_add(&__bridgeJSToNDataSize, rvStr.length);
//			}
			
			__DTXProfilerAddRNBridgeDataCapture(str, args, rvStr, exc, NO);

			free(arguments);

			JSValue *rv = [__jscWrapper.JSValue valueWithJSValueRef:rvRef inContext:[__jscWrapper.JSContext currentContext]];
			return rv;
		};

		JSObjectRef rv = __jscWrapper.JSValueToObject(ctx, __jscWrapper.JSObjectGetProperty(ctx, __jscWrapper.JSContextGetGlobalObject(ctx), name, NULL), NULL);
		return rv;
//		return __orig_JSObjectMakeFunctionWithCallback(ctx, name, callAsFunction);
	}
	
	return __orig_JSObjectMakeFunctionWithCallback(ctx, name, callAsFunction);
}

static JSValueRef (*__orig_JSObjectGetProperty)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
static JSValueRef __dtx_JSObjectGetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception)
{
	JSValueRef rv = __orig_JSObjectGetProperty(ctx, object, propertyName, exception);
	
	NSString* pName = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyName);
	
	__JSValuePropertyMapping[[NSString stringWithFormat:@"%p", rv]] = pName;
	
	return rv;
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
	Class cls = NSClassFromString(@"RCTCxxBridge");
	
	if(cls)
	{
		//Modern RN
		
		__orig_JSObjectMakeFunctionWithCallback = __jscWrapper.JSObjectMakeFunctionWithCallback;
		
		rebind_symbols((struct rebinding[]){
			{"JSObjectMakeFunctionWithCallback",
				__dtx_JSObjectMakeFunctionWithCallback,
				NULL
			},
		}, 1);
		
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
	}
	
	return __orig_UIApplication_run(self, _cmd);
}

__attribute__((constructor))
static void __DTXInitializeRNSampler()
{
	__rnBacktraceSem = dispatch_semaphore_create(0);
	BOOL didLoadCustomJSCWrapper = DTXLoadJSCWrapper(&__jscWrapper);
	
	__JSValuePropertyMapping = [NSMutableDictionary new];
	
	if(didLoadCustomJSCWrapper == YES)
	{
		DTXInitializeSourceMapsSupport(&__jscWrapper);
		__orig_JSObjectCallAsFunction = __jscWrapper.JSObjectCallAsFunction;
		__orig_JSObjectGetProperty = __jscWrapper.JSObjectGetProperty;
	}
	else
	{
		__orig_JSObjectCallAsFunction = dlsym(RTLD_DEFAULT, "JSObjectCallAsFunction");
		__orig_JSObjectGetProperty = dlsym(RTLD_DEFAULT, "JSObjectGetProperty");
	}
	
	Method m = class_getInstanceMethod(UIApplication.class, NSSelectorFromString(@"_run"));
	__orig_UIApplication_run = (void*)method_getImplementation(m);
	method_setImplementation(m, (void*)__dtxinst_UIApplication_run);
	
	rebind_symbols((struct rebinding[]){
		{"JSObjectCallAsFunction",
			__dtx_JSObjectCallAsFunction,
			NULL
		},
		{"JSObjectGetProperty",
			__dtx_JSObjectGetProperty,
			NULL
		},
	}, 2);
	
	struct sigaction sa;
	sigfillset(&sa.sa_mask);
	sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = DTXJSCStackTraceSignalHandler;
	sigaction(SIGCHLD, &sa, NULL);
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
	__eventDispatchQueue = dispatch_queue_create("com.wix.DTXRNSampler-Events", qosAttribute);
}

@implementation DTXReactNativeSampler
{
	uint64_t _initialBridgeNToJSDataSize;
	uint64_t _initialBridgeJSToNDataSize;
	uint64_t _initialBridgeNToJSCallCount;
	uint64_t _initialBridgeJSToNCallCount;
	
	uint64_t _prevBridgeNToJSDataSize;
	uint64_t _prevBridgeJSToNDataSize;
	uint64_t _prevBridgeNToJSCallCount;
	uint64_t _prevBridgeJSToNCallCount;
	
	BOOL _shouldSampleThread;
	BOOL _shouldSymbolicate;
}

+ (BOOL)reactNativeInstalled
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
	uint64_t bridgeNToJSDataSize = atomic_load(&__bridgeNToJSDataSize) - _initialBridgeNToJSDataSize;
	uint64_t bridgeJSToNDataSize = atomic_load(&__bridgeJSToNDataSize) - _initialBridgeJSToNDataSize;
	uint64_t bridgeNToJSCallCount = atomic_load(&__bridgeNToJSCallCount) - _initialBridgeNToJSCallCount;
	uint64_t bridgeJSToNCallCount = atomic_load(&__bridgeJSToNCallCount) - _initialBridgeJSToNCallCount;
	
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
	
	if(_shouldSampleThread)
	{
		pthread_kill(pthread_from_mach_thread_np(safeRNThread), SIGCHLD);
		dispatch_semaphore_wait(__rnBacktraceSem, DISPATCH_TIME_FOREVER);
		
		_currentStackTrace = __rnLastBacktrace;
		
//		if(thread_suspend(safeRNThread) == KERN_SUCCESS)
//		{
//			const char* bt = __jscWrapper.JSContextCreateBacktrace_unsafe(__rnCtx, UINT_MAX);
//			_currentStackTrace = [NSString stringWithUTF8String:bt];
//			thread_resume(safeRNThread);
//		}
//		else
//		{
//			//Thread is already invalid, no stack trace.
//			_currentStackTrace = @"";
//		}
		
		_currentStackTraceSymbolicated = NO;
	}
	
	_cpu = __rnCPUUsage(safeRNThread);
}
@end
