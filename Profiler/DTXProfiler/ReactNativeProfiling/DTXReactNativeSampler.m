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
@import ObjectiveC;
@import Darwin;

static DTXJSCWrapper __jscWrapper;

static atomic_uintmax_t __numberOfRecordings = 0;

static atomic_uintmax_t __bridgeNToJSDataSize = 0;
static atomic_uintmax_t __bridgeNToJSCallCount = 0;
static atomic_uintmax_t __bridgeJSToNDataSize = 0;
static atomic_uintmax_t __bridgeJSToNCallCount = 0;

static _Atomic thread_t __rnThread = MACH_PORT_NULL;

static JSContextRef __rnCtx;

static void resetAtomicVars()
{
	atomic_store(&__bridgeJSToNCallCount, 0);
	atomic_store(&__bridgeNToJSDataSize, 0);
	atomic_store(&__bridgeNToJSCallCount, 0);
	atomic_store(&__bridgeJSToNDataSize, 0);
}

static void installDtxNativeLoggingHook(JSContext* ctx)
{
	ctx.globalObject[@"dtx_numberOfRecordings"] = @(atomic_load(&__numberOfRecordings));
	
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
		JSContext* objcCtx = [__jscWrapper.JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)ctx];
		
		if(__rnCtx == nil || __rnCtx != ctx)
		{
			resetAtomicVars();
			installDtxNativeLoggingHook(objcCtx);
		}
		
		__rnCtx = ctx;
		
		NSString* str = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, name);
		
		objcCtx[str] = ^ {
			
			atomic_fetch_add(&__bridgeJSToNCallCount, 1);
			
			JSValueRef* arguments = malloc(sizeof(JSValueRef) * [__jscWrapper.JSContext currentArguments].count);
			
			[[__jscWrapper.JSContext currentArguments] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				atomic_fetch_add(&__bridgeJSToNDataSize, DTXJSValueJsonStringLengh(ctx, [obj JSValueRef]));
				
				arguments[idx] = [obj JSValueRef];
			}];
			
			JSValueRef exception = NULL;
			
			JSValueRef rvRef = callAsFunction(ctx, JSValueToObject(ctx, [__jscWrapper.JSContext currentCallee].JSValueRef, NULL), JSValueToObject(ctx, [__jscWrapper.JSContext currentThis].JSValueRef, NULL), [__jscWrapper.JSContext currentArguments].count, arguments, &exception);
			
			if(exception)
			{
				JSValue* exceptionValue = [__jscWrapper.JSValue valueWithJSValueRef:exception inContext:[__jscWrapper.JSContext currentContext]];
				[__jscWrapper.JSContext currentContext].exception = exceptionValue;
			}
			
			free(arguments);
			
			JSValue *rv = [__jscWrapper.JSValue valueWithJSValueRef:rvRef inContext:[__jscWrapper.JSContext currentContext]];
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
		
		JSValueRef* arguments = malloc(sizeof(JSValueRef) * [__jscWrapper.JSContext currentArguments].count);
		
		[[__jscWrapper.JSContext currentArguments] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			atomic_fetch_add(&__bridgeJSToNDataSize, DTXJSValueJsonStringLengh(context.JSGlobalContextRef, [obj JSValueRef]));
			
			arguments[idx] = [obj JSValueRef];
		}];
		
		JSValueRef exn = NULL;
		
		JSValue *jsVal = [__jscWrapper.JSValue valueWithObject:origBlock inContext:context];
		JSObjectRef jsObjRef = JSValueToObject(context.JSGlobalContextRef, jsVal.JSValueRef, &exn);
		JSObjectRef thisJsObjRef = JSValueToObject(context.JSGlobalContextRef, [__jscWrapper.JSContext currentThis].JSValueRef, &exn);
		JSValueRef jsValRef = JSObjectCallAsFunction(context.JSGlobalContextRef, jsObjRef, thisJsObjRef, [__jscWrapper.JSContext currentArguments].count, arguments, &exn);
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

__attribute__((constructor))
static void __DTXInitializeRNSampler()
{
	BOOL didSucceed = DTXLoadJSCWrapper(&__jscWrapper);
	
	if(didSucceed == NO)
	{
		return;
	}
	
	DTXInitializeSourceMapsSupport();
	
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
	return NSClassFromString(@"RCTBridge") != nil;
}

- (instancetype)initWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	if(DTXLoadJSCWrapper(NULL) == NO)
	{
		return nil;
	}
	
	self = [super init];
	
	if(self)
	{
		_shouldSampleThread = configuration.collectJavaScriptStackTraces;
		_shouldSymbolicate = configuration.symbolicateJavaScriptStackTraces;
		
		atomic_fetch_add(&__numberOfRecordings, 1);
		
		if(__rnCtx != nil)
		{
			//TODO: Implement in a non-blocking manner.
//			JSContext* objcCtx = [__jscWrapper.JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)__rnCtx];
//			objcCtx.globalObject[@"dtx_numberOfRecordings"] = @(atomic_load(&__numberOfRecordings));
		}
	}
	
	return self;
}

- (void)dealloc
{
	atomic_fetch_sub(&__numberOfRecordings, 1);
	
	if(__rnCtx != nil)
	{
		//TODO: Implement in non-blocking manner.
//		JSContext* objcCtx = [__jscWrapper.JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)__rnCtx];
//		objcCtx.globalObject[@"dtx_numberOfRecordings"] = @(atomic_load(&__numberOfRecordings));
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
		if(thread_suspend(safeRNThread) == KERN_SUCCESS)
		{
			const char* bt = __jscWrapper.JSContextCreateBacktrace_unsafe(__rnCtx, UINT_MAX);
			_currentStackTrace = [NSString stringWithUTF8String:bt];
			thread_resume(safeRNThread);
		}
		else
		{
			//Thread is already invalid, no stack trace.
			_currentStackTrace = @"";
		}

		_currentStackTraceSymbolicated = NO;
	}
		
	_cpu = __rnCPUUsage(safeRNThread);
}
@end
