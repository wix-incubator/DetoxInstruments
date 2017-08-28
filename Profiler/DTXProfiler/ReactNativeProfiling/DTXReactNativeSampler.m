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
@import ObjectiveC;
@import Darwin;

static atomic_uintmax_t __numberOfRecordings = 0;

static atomic_uintmax_t __bridgeNToJSDataSize = 0;
static atomic_uintmax_t __bridgeNToJSCallCount = 0;
static atomic_uintmax_t __bridgeJSToNDataSize = 0;
static atomic_uintmax_t __bridgeJSToNCallCount = 0;

static _Atomic thread_t __rnThread = MACH_PORT_NULL;

static JSContextRef __rnCtx;

JS_EXPORT JSStringRef JSContextCreateBacktrace(JSContextRef ctx, unsigned maxStackSize);

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
	JSStringRef bt = JSContextCreateBacktrace(__rnCtx, UINT_MAX);
    __rnLastBacktrace = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, bt);
	if(bt)
	{
		JSStringRelease(bt);
	}
	
	dispatch_semaphore_signal(__rnBacktraceSem);
}

static void installDtxNativeLoggingHook(JSContext* ctx)
{
	ctx.globalObject[@"dtx_numberOfRecordings"] = @(atomic_load(&__numberOfRecordings));
	
	ctx[@"dtxNativeLoggingHook"] = ^ {
		NSMutableArray *objects = [NSMutableArray new];
		NSArray *logArgs = ((JSValue *)JSContext.currentArguments.firstObject).toArray;
		NSString *logLine = ((JSValue *)JSContext.currentArguments.lastObject).toString;
		for (id object in logArgs) {
			if([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]])
			{
				[objects addObject:object];
			}
		}
		[DTXLoggingRecorder addLogLine:[logLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]] objects:objects];
	};
}

static void (*orig_runRunLoopThread)(id, SEL) = NULL;
static void swz_runRunLoopThread(id self, SEL _cmd)
{
	atomic_store(&__rnThread, mach_thread_self());
	
	orig_runRunLoopThread(self, _cmd);
}


static NSUInteger DTXJSValueJsonStringLengh(JSContextRef ctx, JSValueRef value)
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
		atomic_fetch_add(&__bridgeNToJSDataSize, DTXJSValueJsonStringLengh(ctx, arguments[i]));
	}
	
	return __orig_JSObjectCallAsFunction(ctx, object, thisObject, argumentCount, arguments, exception);
}

static JSObjectRef (*__orig_JSObjectMakeFunctionWithCallback)(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction);

static JSObjectRef __dtx_JSObjectMakeFunctionWithCallback(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction)
{
	if(name != NULL)
	{
		JSContext* objcCtx = [JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)ctx];
		
		if(__rnCtx == nil || __rnCtx != ctx)
		{
			resetAtomicVars();
			installDtxNativeLoggingHook(objcCtx);
		}
		
		__rnCtx = ctx;
		
		NSString* str = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, name);
		
		objcCtx[str] = ^ {
			
			atomic_fetch_add(&__bridgeJSToNCallCount, 1);
			
			JSValueRef* arguments = malloc(sizeof(JSValueRef) * JSContext.currentArguments.count);
			
			[JSContext.currentArguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				atomic_fetch_add(&__bridgeJSToNDataSize, DTXJSValueJsonStringLengh(ctx, [obj JSValueRef]));
				
				arguments[idx] = [obj JSValueRef];
			}];
			
			JSValueRef exception = NULL;
			JSValueRef rvRef = callAsFunction(ctx, JSValueToObject(ctx, JSContext.currentCallee.JSValueRef, NULL), JSValueToObject(ctx, JSContext.currentThis.JSValueRef, NULL), JSContext.currentArguments.count, arguments, &exception);
			
			if(exception)
			{
				JSValue* exceptionValue = [JSValue valueWithJSValueRef:exception inContext:JSContext.currentContext];
				JSContext.currentContext.exception = exceptionValue;
			}
			
			free(arguments);
			
			JSValue *rv = [JSValue valueWithJSValueRef:rvRef inContext:JSContext.currentContext];
			return rv;
		};
		
		JSObjectRef rv = JSValueToObject(ctx, JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), name, NULL), NULL);
		return rv;
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
		installDtxNativeLoggingHook(context);
	}
	
	__orig_setObjectForKeyedSubscript(self, sel, ^{
		
		atomic_fetch_add(&__bridgeJSToNCallCount, 1);
		
		JSValueRef* arguments = malloc(sizeof(JSValueRef) * JSContext.currentArguments.count);
		
		[JSContext.currentArguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			atomic_fetch_add(&__bridgeJSToNDataSize, DTXJSValueJsonStringLengh(context.JSGlobalContextRef, [obj JSValueRef]));
			
			arguments[idx] = [obj JSValueRef];
		}];
		
		JSValueRef exn = NULL;
		
		JSValue *jsVal = [JSValue valueWithObject:origBlock inContext:context];
		JSObjectRef jsObjRef = JSValueToObject(context.JSGlobalContextRef, jsVal.JSValueRef, &exn);
		JSObjectRef thisJsObjRef = JSValueToObject(context.JSGlobalContextRef, JSContext.currentThis.JSValueRef, &exn);
		JSValueRef jsValRef = JSObjectCallAsFunction(context.JSGlobalContextRef, jsObjRef, thisJsObjRef, JSContext.currentArguments.count, arguments, &exn);
		JSValue *rv = [JSValue valueWithJSValueRef:jsValRef inContext:context];
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

__attribute__((constructor))
static void __DTXInitializeRNSampler()
{
	__rnBacktraceSem = dispatch_semaphore_create(0);
	
	rebind_symbols((struct rebinding[]){
		{"JSObjectCallAsFunction",
			__dtx_JSObjectCallAsFunction,
			(void*)&__orig_JSObjectCallAsFunction
		},
	}, 1);

	Class cls = NSClassFromString(@"RCTJSCExecutor");
	Method m = NULL;
	if(cls != NULL)
	{
		//Legacy RN
		
		Class class = [JSContext class];
		Method originalMethod = class_getInstanceMethod(class, @selector(setObject:forKeyedSubscript:));
		__orig_setObjectForKeyedSubscript = (void*)method_getImplementation(originalMethod);
		
		method_setImplementation(originalMethod, (void*)__dtx_setObjectForKeyedSubscript);
		
		cls = NSClassFromString(@"RCTJSCExecutor");
		m = class_getClassMethod(cls, NSSelectorFromString(@"runRunLoopThread"));
	}
	else
	{
		//Modern RN
		
        rebind_symbols((struct rebinding[]){
            {"JSObjectMakeFunctionWithCallback",
                __dtx_JSObjectMakeFunctionWithCallback,
                (void*)&__orig_JSObjectMakeFunctionWithCallback
            },
        }, 1);
        
		cls = NSClassFromString(@"RCTCxxBridge");
		m = class_getInstanceMethod(cls, NSSelectorFromString(@"runJSRunLoop"));
	}
	
	if(m != NULL)
	{
		orig_runRunLoopThread = (void(*)(id, SEL))method_getImplementation(m);
		method_setImplementation(m, (IMP)swz_runRunLoopThread);
	}
	
	struct sigaction sa;
	sigfillset(&sa.sa_mask);
	sa.sa_flags = SA_SIGINFO;
	sa.sa_sigaction = DTXJSCStackTraceSignalHandler;
	sigaction(SIGCHLD, &sa, NULL);
}

@implementation DTXReactNativeSampler
{
	uint64_t _prevBridgeNToJSDataSize;
	uint64_t _prevBridgeJSToNDataSize;
	
	uint64_t _prevBridgeNToJSCallCount;
	uint64_t _prevBridgeJSToNCallCount;
	
	BOOL _shouldSampleThread;
	BOOL _shouldSymbolicate;
}

+ (BOOL)reactNativeInstalled
{
	return (NSClassFromString(@"RCTBridge") != nil);
}

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	self = [super init];
	
	if(self)
	{
		_shouldSampleThread = configuration.collectJavaScriptStackTraces;
		_shouldSymbolicate = configuration.symbolicateJavaScriptStackTraces;
		
		atomic_fetch_add(&__numberOfRecordings, 1);
		
		if(__rnCtx != nil)
		{
			JSContext* objcCtx = [JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)__rnCtx];
			objcCtx.globalObject[@"dtx_numberOfRecordings"] = @(atomic_load(&__numberOfRecordings));
		}
	}
	
	return self;
}

- (void)dealloc
{
	atomic_fetch_sub(&__numberOfRecordings, 1);
	
	if(__rnCtx != nil)
	{
		JSContext* objcCtx = [JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)__rnCtx];
		objcCtx.globalObject[@"dtx_numberOfRecordings"] = @(atomic_load(&__numberOfRecordings));
	}
}

- (void)pollWithTimePassed:(NSTimeInterval)interval
{
	uint64_t bridgeNToJSDataSize = atomic_load(&__bridgeNToJSDataSize);
	uint64_t bridgeJSToNDataSize = atomic_load(&__bridgeJSToNDataSize);
	uint64_t bridgeNToJSCallCount = atomic_load(&__bridgeNToJSCallCount);
	uint64_t bridgeJSToNCallCount = atomic_load(&__bridgeJSToNCallCount);
	
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
		_currentStackTraceSymbolicated = NO;
	}
		
	_cpu = __rnCPUUsage(safeRNThread);
}
@end
