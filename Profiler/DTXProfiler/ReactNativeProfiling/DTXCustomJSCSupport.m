//
//  DTXCustomJSCSupport.c
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 26/09/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCustomJSCSupport.h"
#import "fishhook.h"

#if __has_include("DTXLogging.h")
#import "DTXLogging.h"
DTX_CREATE_LOG(DTXCustomJSCSupport)
#define NSLog dtx_log_error
#endif

@import ObjectiveC;

static CFBundleRef __DTXGetCustomJSCBundle()
{
	static CFBundleRef bundle;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL* thisFrameworkURL = [NSBundle bundleForClass:NSClassFromString(@"DTXReactNativeSampler")].bundleURL;
		NSURL* jscFrameworkURL = [thisFrameworkURL URLByAppendingPathComponent:@"DTX_JSC.framework"];
		bundle = CFBundleCreate(kCFAllocatorDefault, CF(jscFrameworkURL));
	});
	
	return bundle;
}

static void __DTXPoseClassAsClass(Class target, Class posingClass)
{
	if(target == posingClass)
	{
		return;
	}
	
	//Copy class methods
	Class targetMetaclass = object_getClass(target);
	
	unsigned int methodCount = 0;
	Method *methods = class_copyMethodList(object_getClass(posingClass), &methodCount);
	
	for (unsigned int i = 0; i < methodCount; i++)
	{
		Method method = methods[i];
		if(strcmp(sel_getName(method_getName(method)), "load") == 0 || strcmp(sel_getName(method_getName(method)), "initialize") == 0)
		{
			continue;
		}
		
		class_replaceMethod(targetMetaclass, method_getName(method), method_getImplementation(method), method_getTypeEncoding(method));
	}
	
	free(methods);
}

BOOL DTXLoadJSCWrapper(DTXJSCWrapper* output)
{
	CFBundleRef bundle = __DTXGetCustomJSCBundle();
	if(bundle == NULL)
	{
		//Use the system JSC bundle if no custom bundle exists.
		bundle = CFBundleCreate(kCFAllocatorDefault, CF([NSBundle bundleForClass:[JSContext class]].bundleURL));
	}
	
	CFErrorRef error = NULL;
	if(CFBundleLoadExecutableAndReturnError(bundle, &error) == NO)
	{
		NSURL* bundleURL = CFBridgingRelease(CFBundleCopyBundleURL(bundle));
		NSLog(@"Error loading %@: %@", bundleURL.lastPathComponent, error);
		return NO;
	}
	
	static DTXJSCWrapper wrapper = {0};

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		wrapper.JSGlobalContextCreateInGroup = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSGlobalContextCreateInGroup"));
		wrapper.JSGlobalContextRelease = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSGlobalContextRelease"));
		wrapper.JSGlobalContextSetName = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSGlobalContextSetName"));
		wrapper.JSContextGetGlobalContext = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSContextGetGlobalContext"));
		wrapper.JSContextGetGlobalObject = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSContextGetGlobalObject"));
		
		wrapper.JSEvaluateScript = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSEvaluateScript"));
		
		wrapper.JSStringCreateWithUTF8CString = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringCreateWithUTF8CString"));
		wrapper.JSStringCreateWithCFString = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringCreateWithCFString"));
		wrapper.JSStringCopyCFString = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringCopyCFString"));
		wrapper.JSStringGetCharactersPtr = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringGetCharactersPtr"));
		wrapper.JSStringGetLength = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringGetLength"));
		wrapper.JSStringGetMaximumUTF8CStringSize = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringGetMaximumUTF8CStringSize"));
		wrapper.JSStringIsEqualToUTF8CString = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringIsEqualToUTF8CString"));
		wrapper.JSStringRelease = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringRelease"));
		wrapper.JSStringRetain = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSStringRetain"));
		
		wrapper.JSClassCreate = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSClassCreate"));
		wrapper.JSClassRelease = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSClassRelease"));
		
		wrapper.JSObjectCallAsConstructor = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectCallAsConstructor"));
		wrapper.JSObjectCallAsFunction = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectCallAsFunction"));
		wrapper.JSObjectGetPrivate = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectGetPrivate"));
		wrapper.JSObjectGetProperty = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectGetProperty"));
		wrapper.JSObjectGetPropertyAtIndex = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectGetPropertyAtIndex"));
		wrapper.JSObjectIsConstructor = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectIsConstructor"));
		wrapper.JSObjectIsFunction = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectIsFunction"));
		wrapper.JSObjectMake = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectMake"));
		wrapper.JSObjectMakeArray = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectMakeArray"));
		wrapper.JSObjectMakeError = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectMakeError"));
		wrapper.JSObjectMakeFunctionWithCallback = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectMakeFunctionWithCallback"));
		wrapper.JSObjectSetPrivate = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectSetPrivate"));
		wrapper.JSObjectSetProperty = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectSetProperty"));
		
		wrapper.JSObjectCopyPropertyNames = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSObjectCopyPropertyNames"));
		wrapper.JSPropertyNameArrayGetCount = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSPropertyNameArrayGetCount"));
		wrapper.JSPropertyNameArrayGetNameAtIndex = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSPropertyNameArrayGetNameAtIndex"));
		wrapper.JSPropertyNameArrayRelease = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSPropertyNameArrayRelease"));
		
		wrapper.JSValueCreateJSONString = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueCreateJSONString"));
		wrapper.JSValueGetType = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueGetType"));
		wrapper.JSValueMakeFromJSONString = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueMakeFromJSONString"));
		wrapper.JSValueMakeBoolean = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueMakeBoolean"));
		wrapper.JSValueMakeNull = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueMakeNull"));
		wrapper.JSValueMakeNumber = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueMakeNumber"));
		wrapper.JSValueMakeString = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueMakeString"));
		wrapper.JSValueMakeUndefined = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueMakeUndefined"));
		wrapper.JSValueProtect = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueProtect"));
		wrapper.JSValueToBoolean = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueToBoolean"));
		wrapper.JSValueToNumber = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueToNumber"));
		wrapper.JSValueToObject = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueToObject"));
		wrapper.JSValueToStringCopy = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueToStringCopy"));
		wrapper.JSValueUnprotect = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSValueUnprotect"));
		
		wrapper.JSContextCreateBacktrace_unsafe = CFBundleGetFunctionPointerForName(bundle, CFSTR("JSContextCreateBacktrace_unsafe"));
		
		wrapper.JSContext = NSClassFromString(@"JSContext_DTX");
		if(wrapper.JSContext == NULL)
		{
			wrapper.JSContext = NSClassFromString(@"JSContext");
		}
		__DTXPoseClassAsClass(NSClassFromString(@"JSContext"), wrapper.JSContext);
		
		wrapper.JSValue = NSClassFromString(@"JSValue_DTX");
		if(wrapper.JSValue == NULL)
		{
			wrapper.JSValue = NSClassFromString(@"JSValue");
		}
		__DTXPoseClassAsClass(NSClassFromString(@"JSValue"), wrapper.JSValue);
		
		wrapper.JSVirtualMachine = NSClassFromString(@"JSVirtualMachine_DTX");
		if(wrapper.JSVirtualMachine == NULL)
		{
			wrapper.JSVirtualMachine = NSClassFromString(@"JSVirtualMachine");
		}
		__DTXPoseClassAsClass(NSClassFromString(@"JSVirtualMachine"), wrapper.JSVirtualMachine);
		
		wrapper.JSManagedValue = NSClassFromString(@"JSManagedValue_DTX");
		if(wrapper.JSManagedValue == NULL)
		{
			wrapper.JSManagedValue = NSClassFromString(@"JSManagedValue");
		}
		__DTXPoseClassAsClass(NSClassFromString(@"JSManagedValue"), wrapper.JSManagedValue);
		
		struct rebinding rebindings[] = (struct rebinding[]){
			{"JSGlobalContextCreateInGroup", wrapper.JSGlobalContextCreateInGroup, NULL},
			{"JSGlobalContextRelease", wrapper.JSGlobalContextRelease, NULL},
			{"JSGlobalContextSetName", wrapper.JSGlobalContextSetName, NULL},
			{"JSContextGetGlobalContext", wrapper.JSContextGetGlobalContext, NULL},
			{"JSContextGetGlobalObject", wrapper.JSContextGetGlobalObject, NULL},
			{"JSEvaluateScript", wrapper.JSEvaluateScript, NULL},
			{"JSStringCreateWithUTF8CString", wrapper.JSStringCreateWithUTF8CString, NULL},
			{"JSStringCreateWithCFString", wrapper.JSStringCreateWithCFString, NULL},
			{"JSStringCopyCFString", wrapper.JSStringCopyCFString, NULL},
			{"JSStringGetCharactersPtr", wrapper.JSStringGetCharactersPtr, NULL},
			{"JSStringGetLength", wrapper.JSStringGetLength, NULL},
			{"JSStringGetMaximumUTF8CStringSize", wrapper.JSStringGetMaximumUTF8CStringSize, NULL},
			{"JSStringIsEqualToUTF8CString", wrapper.JSStringIsEqualToUTF8CString, NULL},
			{"JSStringRelease", wrapper.JSStringRelease, NULL},
			{"JSStringRetain", wrapper.JSStringRetain, NULL},
			{"JSClassCreate", wrapper.JSClassCreate, NULL},
			{"JSClassRelease", wrapper.JSClassRelease, NULL},
			{"JSObjectCallAsConstructor", wrapper.JSObjectCallAsConstructor, NULL},
			{"JSObjectCallAsFunction", wrapper.JSObjectCallAsFunction, NULL},
			{"JSObjectGetPrivate", wrapper.JSObjectGetPrivate, NULL},
			{"JSObjectGetProperty", wrapper.JSObjectGetProperty, NULL},
			{"JSObjectGetPropertyAtIndex", wrapper.JSObjectGetPropertyAtIndex, NULL},
			{"JSObjectIsConstructor", wrapper.JSObjectIsConstructor, NULL},
			{"JSObjectIsFunction", wrapper.JSObjectIsFunction, NULL},
			{"JSObjectMake", wrapper.JSObjectMake, NULL},
			{"JSObjectMakeArray", wrapper.JSObjectMakeArray, NULL},
			{"JSObjectMakeError", wrapper.JSObjectMakeError, NULL},
			{"JSObjectMakeFunctionWithCallback", wrapper.JSObjectMakeFunctionWithCallback, NULL},
			{"JSObjectSetPrivate", wrapper.JSObjectSetPrivate, NULL},
			{"JSObjectSetProperty", wrapper.JSObjectSetProperty, NULL},
			{"JSObjectCopyPropertyNames", wrapper.JSObjectCopyPropertyNames, NULL},
			{"JSPropertyNameArrayGetCount", wrapper.JSPropertyNameArrayGetCount, NULL},
			{"JSPropertyNameArrayGetNameAtIndex", wrapper.JSPropertyNameArrayGetNameAtIndex, NULL},
			{"JSPropertyNameArrayRelease", wrapper.JSPropertyNameArrayRelease, NULL},
			{"JSValueCreateJSONString", wrapper.JSValueCreateJSONString, NULL},
			{"JSValueGetType", wrapper.JSValueGetType, NULL},
			{"JSValueMakeFromJSONString", wrapper.JSValueMakeFromJSONString, NULL},
			{"JSValueMakeBoolean", wrapper.JSValueMakeBoolean, NULL},
			{"JSValueMakeNull", wrapper.JSValueMakeNull, NULL},
			{"JSValueMakeNumber", wrapper.JSValueMakeNumber, NULL},
			{"JSValueMakeString", wrapper.JSValueMakeString, NULL},
			{"JSValueMakeUndefined", wrapper.JSValueMakeUndefined, NULL},
			{"JSValueProtect", wrapper.JSValueProtect, NULL},
			{"JSValueToBoolean", wrapper.JSValueToBoolean, NULL},
			{"JSValueToNumber", wrapper.JSValueToNumber, NULL},
			{"JSValueToObject", wrapper.JSValueToObject, NULL},
			{"JSValueToStringCopy", wrapper.JSValueToStringCopy, NULL},
			{"JSValueUnprotect", wrapper.JSValueUnprotect, NULL},
		};
		
		//Perform mother of all swizzles.
		rebind_symbols(rebindings, sizeof(rebindings)/sizeof(struct rebinding));
	});
	
	if(output != NULL)
	{
		memcpy(output, &wrapper, sizeof(DTXJSCWrapper));
	}
	
	return YES;
}
