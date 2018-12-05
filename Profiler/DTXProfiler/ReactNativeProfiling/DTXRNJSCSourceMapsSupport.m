//
//  DTXRNJSCSourceMapsSupport.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 02/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRNJSCSourceMapsSupport.h"
#import "AutoCoding.h"
#if DTX_PROFILER
#import "fishhook.h"
#import <stdatomic.h>

@import JavaScriptCore;
@import ObjectiveC;

static _Atomic(const void*) __rnSourceURL;
static _Atomic(const void*) __sourceMapsURL;
static _Atomic(const void*) __rnSourceMapsParser;

static JSValueRef (*__orig_JSEvaluateScript)(JSContextRef ctx, JSStringRef script, JSObjectRef thisObject, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception);

static JSValueRef __dtx_JSEvaluateScript(JSContextRef ctx, JSStringRef script, JSObjectRef thisObject, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception)
{
	@autoreleasepool
	{
		NSString* srcString = CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, script));
		
		NSArray<NSString*>* srcSplit = [srcString componentsSeparatedByString:@"sourceMappingURL="];
		
		if(srcSplit.count > 1)
		{
			NSURL* rnSourceURL = NS(atomic_load(&__rnSourceURL));
			atomic_store(&__sourceMapsURL, CFBridgingRetain([NSURL URLWithString:srcString.lastPathComponent relativeToURL:rnSourceURL]));
			
#ifdef DTX_EMBED_SOURCEMAPS
			srcString = [srcSplit.firstObject stringByAppendingString:[NSString stringWithFormat:@"sourceMappingURL=data:application/json;base64,%@", [sourceMapsData base64EncodedStringWithOptions:0]]];
			
			JSStringRelease(script);
			
			script = JSStringCreateWithCFString(CF(srcString));
#endif
		}
	}
	
	return __orig_JSEvaluateScript(ctx, script, thisObject, sourceURL, startingLineNumber, exception);
}

static id (*__orig_RCTBridge_initWithDelegate_bundleURL_moduleProvider_launchOptions)(id self, SEL sel, id delegate, NSURL* bundleURL, id block, id launchOptions);
static id __dtx_RCTBridge_initWithDelegate_bundleURL_moduleProvider_launchOptions(id self, SEL sel, id delegate, NSURL* bundleURL, id block, id launchOptions)
{
	atomic_store(&__rnSourceURL, CFBridgingRetain(bundleURL));
	
	return __orig_RCTBridge_initWithDelegate_bundleURL_moduleProvider_launchOptions(self, sel, delegate, bundleURL, block, launchOptions);
}

extern void DTXRNGetCurrentWorkingSourceMapsData(void (^completion)(NSData*))
{
	NSURL* sourceMapsURL = NS(atomic_load(&__sourceMapsURL));
	if(sourceMapsURL == nil)
	{
		completion(nil);
	}
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
		completion([NSData dataWithContentsOfURL:sourceMapsURL]);
	});
}

extern NSArray* DTXRNSymbolicateJSCBacktrace(NSArray<NSString*>* backtrace, BOOL* currentStackTraceSymbolicated)
{
	DTXSourceMapsParser* parser = NS(atomic_load(&__rnSourceMapsParser));
	if(parser == nil)
	{
		NSURL* sourceMapsURL = NS(atomic_load(&__sourceMapsURL));
		if(sourceMapsURL != nil)
		{
			NSData* sourceMapsData = [NSData dataWithContentsOfURL:sourceMapsURL];
			NSDictionary* sourceMaps;
			
			@try {
				sourceMaps = [NSJSONSerialization JSONObjectWithData:sourceMapsData options:0 error:NULL];
			}
			@catch (NSException* e) {}
			
			if(sourceMaps)
			{
				parser = [DTXSourceMapsParser sourceMapsParserForSourceMaps:sourceMaps];
				atomic_store(&__rnSourceMapsParser, CFBridgingRetain(parser));
			}
		}
		else
		{
			*currentStackTraceSymbolicated = NO;
			return backtrace;
		}
	}
#else
NSArray* DTXRNSymbolicateJSCBacktrace(DTXSourceMapsParser* parser, NSArray<NSString*>* backtrace, BOOL* currentStackTraceSymbolicated)
{
	NSCParameterAssert(parser != nil);
#endif
	NSRegularExpression* expr = [NSRegularExpression regularExpressionWithPattern:@"\\#(\\d+) (.*)\\(\\) at (.*?)(:(\\d+))?$" options:0 error:NULL];
	
	NSMutableArray* symbolicatedLines = [NSMutableArray new];
	
	for (NSString* obj in backtrace) {
		NSTextCheckingResult* match = [expr matchesInString:obj options:0 range:NSMakeRange(0, obj.length)].firstObject;
		
		if(match.numberOfRanges != 6)
		{
			//Unsupported format - add line as is.
			[symbolicatedLines addObject:obj];
			break;
		}
		
		//		NSString* stackFrameNumber = [obj substringWithRange:[match rangeAtIndex:1]];
		NSString* funcName = [obj substringWithRange:[match rangeAtIndex:2]];
		NSString* codeURLString = [obj substringWithRange:[match rangeAtIndex:3]];
		DTXSourcePosition* pos = [DTXSourcePosition new];
		pos.column = @0;
		
		DTXSourcePosition* symbolicated = nil;
		
		if([match rangeAtIndex:4].location != NSNotFound)
		{
			NSInteger lineNumber = [obj substringWithRange:[match rangeAtIndex:5]].integerValue;
			
			pos.line = @(lineNumber);
			
			symbolicated = [parser originalPositionForPosition:pos];
		}
		
		if(symbolicated == nil)
		{
			symbolicated = pos;
			symbolicated.sourceFileName = codeURLString;
		}
		
		if(symbolicated.symbolName == nil)
		{
			symbolicated.symbolName = funcName;
		}
		
		//		NSString* frame = [NSString stringWithFormat:@"#%@ %@() at %@:%@", stackFrameNumber, symbolicated.symbolName ?: funcName, symbolicated.sourceFileName, symbolicated.line];
		[symbolicatedLines addObject:[symbolicated dictionaryRepresentation]];
	}
	
	*currentStackTraceSymbolicated = YES;
	return symbolicatedLines;
}

#if DTX_PROFILER
void DTXInitializeSourceMapsSupport(DTXJSCWrapper* wrapper)
{
	__orig_JSEvaluateScript = wrapper->JSEvaluateScript;
	
	rebind_symbols((struct rebinding[]){
		{"JSEvaluateScript",
			__dtx_JSEvaluateScript,
			NULL
		},
	}, 1);
	
	Class cls = NSClassFromString(@"RCTBridge");
	Method m = class_getInstanceMethod(cls, NSSelectorFromString(@"initWithDelegate:bundleURL:moduleProvider:launchOptions:"));
	
	__orig_RCTBridge_initWithDelegate_bundleURL_moduleProvider_launchOptions = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_RCTBridge_initWithDelegate_bundleURL_moduleProvider_launchOptions);
}
#endif
