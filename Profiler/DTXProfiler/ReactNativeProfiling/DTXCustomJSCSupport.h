//
//  DTXCustomJSCSupport.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 26/09/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#pragma once

@import JavaScriptCore;

#define DTX_WRAPPER_METHOD(m) __typeof(&m) m

typedef struct DTXJSCWrapper {
	// JSGlobalContext
	DTX_WRAPPER_METHOD(JSGlobalContextCreateInGroup);
	DTX_WRAPPER_METHOD(JSGlobalContextRelease);
	DTX_WRAPPER_METHOD(JSGlobalContextSetName);
	
	// JSContext
	DTX_WRAPPER_METHOD(JSContextGetGlobalContext);
	DTX_WRAPPER_METHOD(JSContextGetGlobalObject);
	
	// JSEvaluate
	DTX_WRAPPER_METHOD(JSEvaluateScript);
	
	// JSString
	DTX_WRAPPER_METHOD(JSStringCreateWithUTF8CString);
	DTX_WRAPPER_METHOD(JSStringCreateWithCFString);
	DTX_WRAPPER_METHOD(JSStringCopyCFString);
	DTX_WRAPPER_METHOD(JSStringGetCharactersPtr);
	DTX_WRAPPER_METHOD(JSStringGetLength);
	DTX_WRAPPER_METHOD(JSStringGetMaximumUTF8CStringSize);
	DTX_WRAPPER_METHOD(JSStringIsEqualToUTF8CString);
	DTX_WRAPPER_METHOD(JSStringRelease);
	DTX_WRAPPER_METHOD(JSStringRetain);
	
	// JSClass
	DTX_WRAPPER_METHOD(JSClassCreate);
	DTX_WRAPPER_METHOD(JSClassRelease);
	
	// JSObject
	DTX_WRAPPER_METHOD(JSObjectCallAsConstructor);
	DTX_WRAPPER_METHOD(JSObjectCallAsFunction);
	DTX_WRAPPER_METHOD(JSObjectGetPrivate);
	DTX_WRAPPER_METHOD(JSObjectGetProperty);
	DTX_WRAPPER_METHOD(JSObjectGetPropertyAtIndex);
	DTX_WRAPPER_METHOD(JSObjectIsConstructor);
	DTX_WRAPPER_METHOD(JSObjectIsFunction);
	DTX_WRAPPER_METHOD(JSObjectMake);
	DTX_WRAPPER_METHOD(JSObjectMakeArray);
	DTX_WRAPPER_METHOD(JSObjectMakeError);
	DTX_WRAPPER_METHOD(JSObjectMakeFunctionWithCallback);
	DTX_WRAPPER_METHOD(JSObjectSetPrivate);
	DTX_WRAPPER_METHOD(JSObjectSetProperty);
	
	// JSPropertyNameArray
	DTX_WRAPPER_METHOD(JSObjectCopyPropertyNames);
	DTX_WRAPPER_METHOD(JSPropertyNameArrayGetCount);
	DTX_WRAPPER_METHOD(JSPropertyNameArrayGetNameAtIndex);
	DTX_WRAPPER_METHOD(JSPropertyNameArrayRelease);
	
	// JSValue
	DTX_WRAPPER_METHOD(JSValueCreateJSONString);
	DTX_WRAPPER_METHOD(JSValueGetType);
	DTX_WRAPPER_METHOD(JSValueMakeFromJSONString);
	DTX_WRAPPER_METHOD(JSValueMakeBoolean);
	DTX_WRAPPER_METHOD(JSValueMakeNull);
	DTX_WRAPPER_METHOD(JSValueMakeNumber);
	DTX_WRAPPER_METHOD(JSValueMakeString);
	DTX_WRAPPER_METHOD(JSValueMakeUndefined);
	DTX_WRAPPER_METHOD(JSValueProtect);
	DTX_WRAPPER_METHOD(JSValueToBoolean);
	DTX_WRAPPER_METHOD(JSValueToNumber);
	DTX_WRAPPER_METHOD(JSValueToObject);
	DTX_WRAPPER_METHOD(JSValueToStringCopy);
	DTX_WRAPPER_METHOD(JSValueUnprotect);
	
	// Backtrace
	const char* (*JSContextCreateBacktrace_unsafe)(JSContextRef ctx, unsigned maxStackSize);
	
	// Objective-C API
	Class JSContext;
	Class JSValue;
	Class JSVirtualMachine;
	Class JSManagedValue;
} DTXJSCWrapper;

extern BOOL DTXLoadJSCWrapper(DTXJSCWrapper* output);
