//
//  DTXExternalProtocolHooking.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXExternalProtocolHooking.h"
#import "DTXExternalProtocolStorage.h"
#import "DTXURLProtocol.h"
@import ObjectiveC;

static void* __DTXUniqueIdentifierForProtocolInstanceKey = &__DTXUniqueIdentifierForProtocolInstanceKey;

DTX_CREATE_LOG(ExternalProtocolHooking);

void (*__orig_URLProtocol_didReceiveResponse_cacheStoragePolicy)(id, SEL, NSURLProtocol*, NSURLResponse*, NSURLCacheStoragePolicy);
static void __dtx_URLProtocol_didReceiveResponse_cacheStoragePolicy(id self, SEL _cmd, NSURLProtocol* protocol, NSURLResponse* response, NSURLCacheStoragePolicy policy)
{
	[_DTXExternalProtocolStorage setResponse:response forProtocolInstance:protocol];
	
	__orig_URLProtocol_didReceiveResponse_cacheStoragePolicy(self, _cmd, protocol, response, policy);
}

void (*__orig_URLProtocol_didLoadData)(id, SEL, NSURLProtocol*, NSData*);
static void __dtx_URLProtocol_didLoadData(id self, SEL _cmd, NSURLProtocol* protocol, NSData* data)
{
	[_DTXExternalProtocolStorage appendLoadedData:data forProtocolInstance:protocol];
	
	__orig_URLProtocol_didLoadData(self, _cmd, protocol, data);
}

void (*__orig_URLProtocolDidFinishLoading)(id, SEL, NSURLProtocol*);
static void __dtx_URLProtocolDidFinishLoading(id self, SEL _cmd, NSURLProtocol* protocol)
{
	NSURLResponse* response;
	NSData* data;
	NSError* error;
	
	[_DTXExternalProtocolStorage getResponse:&response data:&data error:&error forProtocolInstance:protocol];
	
	NSString* uniqueIdentifier = objc_getAssociatedObject(protocol, __DTXUniqueIdentifierForProtocolInstanceKey);
	
	[DTXURLProtocol.delegate urlProtocol:self didFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier];
	
	__orig_URLProtocolDidFinishLoading(self, _cmd, protocol);
}

void (*__orig_URLProtocol_didFailWithError)(id, SEL, NSURLProtocol*, NSError*);
static void __dtx_URLProtocol_didFailWithError(id self, SEL _cmd, NSURLProtocol* protocol, NSError* error)
{
	[_DTXExternalProtocolStorage setError:error forProtocolInstance:protocol];
	
	__orig_URLProtocol_didFailWithError(self, _cmd, protocol, error);
}

static BOOL (*__orig_registerClass)(id, SEL, Class);
static BOOL __dtx_registerClass(id self, SEL _cmd, Class protocolClass)
{
	return __orig_registerClass(self, _cmd, protocolClass);
}

void (*__orig_setProtocolClasses)(id, SEL, NSArray<Class>*);
void __dtx_setProtocolClasses(id self, SEL _cmd, NSArray<Class>* classes)
{
	__orig_setProtocolClasses(self, _cmd, classes);
}

NSArray<Class>* (*__orig_protocolClasses)(id, SEL);
NSArray<Class>* __dtx_protocolClasses(id self, SEL _cmd)
{
	NSMutableArray<Class>* currentProtocols = [__orig_protocolClasses(self, _cmd) mutableCopy];
	
	NSMutableArray<Class>* userProtocols = [NSMutableArray new];
	NSMutableArray<Class>* injectedProtocols = [NSMutableArray new];
	NSMutableArray<Class>* systemProtocols = [NSMutableArray new];
	
	[currentProtocols enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* bundleName = [NSBundle bundleForClass:obj].executableURL.lastPathComponent;
		
		if([bundleName isEqualToString:@"CFNetwork"])
		{
			[systemProtocols addObject:obj];
			return;
		}
		
		if([bundleName isEqualToString:@"DTXProfiler"])
		{
			[injectedProtocols addObject:obj];
			return;
		}
		
		Class cls = obj;
		if([obj conformsToProtocol:@protocol(_DTXUserProtocolIsSwizzled)] == NO)
		{
			NSString* className = [NSString stringWithFormat:@"__dtx_%s", class_getName(obj)];
			cls = objc_getClass(className.UTF8String);
			
			if(cls == nil)
			{
				cls = objc_allocateClassPair(obj, className.UTF8String, 0);
				
				class_addMethod(cls, @selector(startLoading), imp_implementationWithBlock(^ (NSURLProtocol* self) {
					NSString* uniqueIdentifier = [NSProcessInfo processInfo].globallyUniqueString;
					objc_setAssociatedObject(self, __DTXUniqueIdentifierForProtocolInstanceKey, uniqueIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
					
					[_DTXExternalProtocolStorage addProtocolInstance:self];
					
					[DTXURLProtocol.delegate urlProtocol:self didStartRequest:self.request uniqueIdentifier:uniqueIdentifier];
					
					//Call [super startLoading];
					struct objc_super super = {.receiver = self, .super_class = [self superclass]};
					void (*superStartLoading)(struct objc_super*, SEL) = (void*)objc_msgSendSuper;
					superStartLoading(&super, @selector(startLoading));
				}), method_getTypeEncoding(class_getInstanceMethod([NSURLProtocol class], @selector(startLoading))));
				
				objc_registerClassPair(cls);
			}
		}
		
		[userProtocols addObject:cls];
	}];
	
	NSMutableArray<Class>* rv = [NSMutableArray new];
	[rv addObjectsFromArray:userProtocols];
	[rv addObjectsFromArray:injectedProtocols];
	[rv addObjectsFromArray:systemProtocols];
	
	return rv;
}

static NSURLSessionConfiguration* (*__orig_defaultSessionConfiguration)(id, SEL);
static NSURLSessionConfiguration* __dtx_defaultSessionConfiguration(id self, SEL _cmd)
{
	NSURLSessionConfiguration *defaultSessionConfiguration = __orig_defaultSessionConfiguration(self, _cmd);
	NSMutableArray<Class>* originalProtocols = defaultSessionConfiguration.protocolClasses.mutableCopy;
	[originalProtocols insertObject:[DTXURLProtocol class] atIndex:0];
	defaultSessionConfiguration.protocolClasses = originalProtocols;
	return defaultSessionConfiguration;
}

static NSURLSessionConfiguration* (*__orig_ephemeralSessionConfiguration)(id, SEL);
static NSURLSessionConfiguration* __dtx_ephemeralSessionConfiguration(id self, SEL _cmd)
{
	NSURLSessionConfiguration *ephemeralSessionConfiguration = __orig_ephemeralSessionConfiguration(self, _cmd);
	NSMutableArray<Class>* originalProtocols = ephemeralSessionConfiguration.protocolClasses.mutableCopy;
	[originalProtocols insertObject:[DTXURLProtocol class] atIndex:0];
	ephemeralSessionConfiguration.protocolClasses = originalProtocols;
	return ephemeralSessionConfiguration;
}

__attribute__((constructor))
static void __DTXHookProtocolClients()
{
	Class cls = NSClassFromString(@"__NSCFURLProtocolClient_NS");
	if(cls == nil)
	{
		dtx_log_error(@"Class \"__NSCFURLProtocolClient_NS\" not found, bailing out.");
		return;
	}
	
	Method m = class_getInstanceMethod(cls, @selector(URLProtocol:didReceiveResponse:cacheStoragePolicy:));
	__orig_URLProtocol_didReceiveResponse_cacheStoragePolicy = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_URLProtocol_didReceiveResponse_cacheStoragePolicy);
	
	m = class_getInstanceMethod(cls, @selector(URLProtocol:didLoadData:));
	__orig_URLProtocol_didLoadData = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_URLProtocol_didLoadData);
	
	m = class_getInstanceMethod(cls, @selector(URLProtocolDidFinishLoading:));
	__orig_URLProtocolDidFinishLoading = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_URLProtocolDidFinishLoading);
	
	m = class_getInstanceMethod(cls, @selector(URLProtocol:didFailWithError:));
	__orig_URLProtocol_didFailWithError = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_URLProtocol_didFailWithError);
	
	m = class_getClassMethod([NSURLProtocol class], @selector(registerClass:));
	__orig_registerClass = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_registerClass);
	
	m = class_getInstanceMethod(NSClassFromString(@"__NSCFURLSessionConfiguration"), @selector(setProtocolClasses:));
	__orig_setProtocolClasses = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_setProtocolClasses);
	
	m = class_getInstanceMethod(NSClassFromString(@"__NSURLSessionLocal"), NSSelectorFromString(@"_protocolClasses"));
	__orig_protocolClasses = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_protocolClasses);
	
	m = class_getClassMethod([NSURLSessionConfiguration class], @selector(defaultSessionConfiguration));
	__orig_defaultSessionConfiguration = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_defaultSessionConfiguration);
	
	m = class_getClassMethod([NSURLSessionConfiguration class], @selector(ephemeralSessionConfiguration));
	__orig_ephemeralSessionConfiguration = (void*)method_getImplementation(m);
	method_setImplementation(m, (IMP)__dtx_ephemeralSessionConfiguration);
}
