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
#import "DTXReactNativeEventsRecorder.h"
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
		[DTXLoggingRecorder addLogLine:[logLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]] objects:objects];
	};
}

static void installDTXSignpostHook(JSContext* ctx)
{
	ctx[@"dtxMarkEventIntervalBegin"] = (id) ^ (NSString* category, NSString* name, NSString* additionalInfoStart) {
		return [DTXReactNativeEventsRecorder markEventIntervalBeginWithCategory:category name:name additionalInfo:additionalInfoStart];
	};
	
	ctx[@"dtxMarkEventIntervalEnd"] = (NSString*) ^ (id identifier, NSInteger eventStatus, NSString* additionalInfoEnd) {
		[DTXReactNativeEventsRecorder markEventIntervalEndWithIdentifiersData:identifier eventStatus:eventStatus additionalInfo:additionalInfoEnd];
	};
	
	ctx[@"dtxMarkEvent"] = (NSString*) ^ (NSString* category, NSString* name, NSInteger eventStatus, NSString* additionalInfoStart) {
		[DTXReactNativeEventsRecorder markEventWithCategory:category name:name eventStatus:eventStatus additionalInfo:additionalInfoStart];
	};
}

static void (*orig_runRunLoopThread)(id, SEL) = NULL;
static void swz_runRunLoopThread(id self, SEL _cmd)
{
	atomic_store(&__rnThread, mach_thread_self());
	
	orig_runRunLoopThread(self, _cmd);
}


static NSUInteger DTXJSValueJsonStringLength(JSContextRef ctx, JSValueRef value)
{
	NSUInteger rv = 0;
	
	JSValueRef exception = NULL;
	JSStringRef jsonStrRef = JSValueCreateJSONString(ctx, value, 0, &exception);
	
	if(exception == NULL && jsonStrRef != NULL)
	{
		NSString* jsonStr = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, jsonStrRef);
		rv = jsonStr.length;
	}
	
	if(jsonStrRef != NULL)
	{
		JSStringRelease(jsonStrRef);
	}
	
	return rv;
}

static JSValueRef (*__orig_JSObjectCallAsFunction)(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);

static JSValueRef __dtx_JSObjectCallAsFunction(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception)
{
	atomic_fetch_add(&__bridgeNToJSCallCount, 1);
	
	for(size_t i = 0; i < argumentCount; i++)
	{
		atomic_fetch_add(&__bridgeNToJSDataSize, DTXJSValueJsonStringLength(ctx, arguments[i]));
	}
	
	return __orig_JSObjectCallAsFunction(ctx, object, thisObject, argumentCount, arguments, exception);
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

			[[__jscWrapper.JSContext currentArguments] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				atomic_fetch_add(&__bridgeJSToNDataSize, DTXJSValueJsonStringLength(ctx, [obj JSValueRef]));

				arguments[idx] = [obj JSValueRef];
			}];

			JSValueRef exception = NULL;

			JSValueRef rvRef = callAsFunction(ctx, __jscWrapper.JSValueToObject(ctx, [__jscWrapper.JSContext currentCallee].JSValueRef, NULL), __jscWrapper.JSValueToObject(ctx, [__jscWrapper.JSContext currentThis].JSValueRef, NULL), [__jscWrapper.JSContext currentArguments].count, arguments, &exception);

			if(exception)
			{
				JSValue* exceptionValue = [__jscWrapper.JSValue valueWithJSValueRef:exception inContext:[__jscWrapper.JSContext currentContext]];
				[__jscWrapper.JSContext currentContext].exception = exceptionValue;
			}

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

static void (*__orig_setObjectForKeyedSubscript)(id self, SEL sel, id obj, id<NSCopying> key);

static void __dtx_setObjectForKeyedSubscript(JSContext * self, SEL sel, id origBlock, id<NSCopying> key)
{
	JSContext *context = self;
	
	BOOL shouldInstallDtxNativeLoggingHook = (__rnCtx == nil || __rnCtx != context.JSGlobalContextRef);
	
	__rnCtx = context.JSGlobalContextRef;
	
	if(shouldInstallDtxNativeLoggingHook)
	{
		resetAtomicVars();
		installDTXNativeLoggingHook(context);
	}
	
	__orig_setObjectForKeyedSubscript(self, sel, ^{
		
		atomic_fetch_add(&__bridgeJSToNCallCount, 1);
		
		JSValueRef* arguments = malloc(sizeof(JSValueRef) * [__jscWrapper.JSContext currentArguments].count);
		
		[[__jscWrapper.JSContext currentArguments] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			atomic_fetch_add(&__bridgeJSToNDataSize, DTXJSValueJsonStringLength(context.JSGlobalContextRef, [obj JSValueRef]));
			
			arguments[idx] = [obj JSValueRef];
		}];
		
		JSValueRef exn = NULL;
		
		JSValue *jsVal = [__jscWrapper.JSValue valueWithObject:origBlock inContext:context];
		JSObjectRef jsObjRef = __jscWrapper.JSValueToObject(context.JSGlobalContextRef, jsVal.JSValueRef, &exn);
		JSObjectRef thisJsObjRef = __jscWrapper.JSValueToObject(context.JSGlobalContextRef, [__jscWrapper.JSContext currentThis].JSValueRef, &exn);
		JSValueRef jsValRef = __jscWrapper.JSObjectCallAsFunction(context.JSGlobalContextRef, jsObjRef, thisJsObjRef, [__jscWrapper.JSContext currentArguments].count, arguments, &exn);
		JSValue *rv = [__jscWrapper.JSValue valueWithJSValueRef:jsValRef inContext:context];
		free(arguments);
		
		return rv;
	}, key);
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

static int (*__orig_UIApplicationMain)(int argc, char * _Nonnull * _Null_unspecified argv, NSString * _Nullable principalClassName, NSString * _Nullable delegateClassName);
static int __dtx_rn_UIApplicationMain(int argc, char * _Nonnull * _Null_unspecified argv, NSString * _Nullable principalClassName, NSString * _Nullable delegateClassName)
{
	Class cls = NSClassFromString(@"RCTJSCExecutor");
	Method m = NULL;
	if(cls != NULL)
	{
		//Legacy RN
		
		Class class = [__jscWrapper.JSContext class];
		Method originalMethod = class_getInstanceMethod(class, @selector(setObject:forKeyedSubscript:));
		__orig_setObjectForKeyedSubscript = (void*)method_getImplementation(originalMethod);
		
		method_setImplementation(originalMethod, (void*)__dtx_setObjectForKeyedSubscript);
		
		cls = NSClassFromString(@"RCTJSCExecutor");
		m = class_getClassMethod(cls, NSSelectorFromString(@"runRunLoopThread"));
	}
	else
	{
		//Modern RN
		
		__orig_JSObjectMakeFunctionWithCallback = __jscWrapper.JSObjectMakeFunctionWithCallback;
		
		rebind_symbols((struct rebinding[]){
			{"JSObjectMakeFunctionWithCallback",
				__dtx_JSObjectMakeFunctionWithCallback,
				NULL
			},
		}, 1);
		
		cls = NSClassFromString(@"RCTCxxBridge");
		m = class_getClassMethod(cls, NSSelectorFromString(@"runRunLoop"));
		if(m == NULL)
		{
			m = class_getInstanceMethod(cls, NSSelectorFromString(@"runJSRunLoop"));
		}
	}
	
	if(m != NULL)
	{
		orig_runRunLoopThread = (void(*)(id, SEL))method_getImplementation(m);
		method_setImplementation(m, (IMP)swz_runRunLoopThread);
	}
	
	return __orig_UIApplicationMain(argc, argv, principalClassName, delegateClassName);
}

__attribute__((constructor))
static void __DTXInitializeRNSampler()
{
	__rnBacktraceSem = dispatch_semaphore_create(0);
	BOOL didLoadCustomJSCWrapper = DTXLoadJSCWrapper(&__jscWrapper);
	
	if(didLoadCustomJSCWrapper == YES)
	{
		DTXInitializeSourceMapsSupport(&__jscWrapper);
		__orig_JSObjectCallAsFunction = __jscWrapper.JSObjectCallAsFunction;
	}
	else
	{
		__orig_JSObjectCallAsFunction = dlsym(RTLD_DEFAULT, "JSObjectCallAsFunction");
	}
	
	__orig_UIApplicationMain = dlsym(RTLD_DEFAULT, "UIApplicationMain");
	
	rebind_symbols((struct rebinding[]){
		{"JSObjectCallAsFunction",
			__dtx_JSObjectCallAsFunction,
			NULL
		},
		{"UIApplicationMain",
			__dtx_rn_UIApplicationMain,
			NULL
		},
	}, 2);
	
	struct sigaction sa;
	sigfillset(&sa.sa_mask);
	sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = DTXJSCStackTraceSignalHandler;
	sigaction(SIGCHLD, &sa, NULL);
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
	uint64_t bridgeNToJSDataSize = atomic_load(&__bridgeNToJSDataSize);
	uint64_t bridgeJSToNDataSize = atomic_load(&__bridgeJSToNDataSize);
	uint64_t bridgeNToJSCallCount = atomic_load(&__bridgeNToJSCallCount);
	uint64_t bridgeJSToNCallCount = atomic_load(&__bridgeJSToNCallCount);
	
	_initialBridgeNToJSCallCount = bridgeNToJSCallCount;
	_initialBridgeJSToNCallCount = bridgeJSToNCallCount;
	_initialBridgeNToJSDataSize = bridgeNToJSDataSize;
	_initialBridgeJSToNDataSize = bridgeJSToNDataSize;
	
	BOOL didLoadCustomJSCWrapper = DTXLoadJSCWrapper(NULL);
	
	self = [super init];
	
	if(self)
	{
		_shouldSampleThread = didLoadCustomJSCWrapper && configuration.collectJavaScriptStackTraces;
		_shouldSymbolicate = didLoadCustomJSCWrapper && configuration.symbolicateJavaScriptStackTraces;
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
