//
//  NSURLConnection+DTXLegacyConnectionRecording.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 10/21/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "NSURLConnection+DTXLegacyConnectionRecording.h"
#import "DTXProfiler-Private.h"
#import "NSObject+AttachedObjects.h"
@import ObjectiveC;

extern _Thread_local BOOL _protocolLoading;

static void* __DTXConnectionUnique = &__DTXConnectionUnique;

static void* __DTXConnectionDidStart = &__DTXConnectionDidStart;
static void* __DTXConnectionDidFail = &__DTXConnectionDidFail;
static void* __DTXConnectionResponse = &__DTXConnectionResponse;
static void* __DTXConnectionData = &__DTXConnectionData;

/*
 if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:_cmd])
 {
 struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
 BOOL (*super_class)(struct objc_super*, SEL, id, id) = (void*)objc_msgSendSuper;
 rv = super_class(&super, _cmd, application, launchOptions);
 }
 */

@interface __DTX_DelegateProxy : NSObject <NSURLConnectionDataDelegate> @end

@implementation __DTX_DelegateProxy

- (void)__dtx_net_canaryInTheCoalMine {}

- (nullable NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response
{
	if([[self dtx_attachedObjectForKey:__DTXConnectionDidStart] boolValue] == NO)
	{
		__DTXProfilerMarkNetworkRequestBegin(request, [connection dtx_attachedObjectForKey:__DTXConnectionUnique], NSDate.date);
		[self dtx_attachObject:@YES forKey:__DTXConnectionDidStart];
	}
	
	NSURLRequest* rv = request;
	if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:_cmd])
	{
		struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
		NSURLRequest* (*super_class)(struct objc_super*, SEL, id, id, id) = (void*)objc_msgSendSuper;
		rv = super_class(&super, _cmd, connection, request, response);
	}
	return rv;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if(error != nil)
	{
		[self dtx_attachObject:@YES forKey:__DTXConnectionDidFail];
		
		__DTXProfilerMarkNetworkResponseEnd([self dtx_attachedObjectForKey:__DTXConnectionResponse], [self dtx_attachedObjectForKey:__DTXConnectionData], error, [connection dtx_attachedObjectForKey:__DTXConnectionUnique], NSDate.date);
	}
	
	if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:_cmd])
	{
		struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
		void (*super_class)(struct objc_super*, SEL, id, id) = (void*)objc_msgSendSuper;
		super_class(&super, _cmd, connection, error);
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[self dtx_attachObject:[response copy] forKey:__DTXConnectionResponse];
	
	if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:_cmd])
	{
		struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
		void (*super_class)(struct objc_super*, SEL, id, id) = (void*)objc_msgSendSuper;
		super_class(&super, _cmd, connection, response);
	}
}

- (void)__dtx_appendAttachedData:(NSData*)data
{
	NSMutableData* aggregatedData = [self dtx_attachedObjectForKey:__DTXConnectionData];
	if(aggregatedData == nil)
	{
		aggregatedData = [NSMutableData new];
	}
	
	[aggregatedData appendData:data];
	
	[self dtx_attachObject:aggregatedData forKey:__DTXConnectionData];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data lengthReceived:(long long)lengthReceived
{
	[self __dtx_appendAttachedData:data];
	
	if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:_cmd])
	{
		struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
		void (*super_class)(struct objc_super*, SEL, id, id, long long) = (void*)objc_msgSendSuper;
		super_class(&super, _cmd, connection, data, lengthReceived);
	}
	else if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:@selector(connection:didReceiveData:)])
	{
		struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
		void (*super_class)(struct objc_super*, SEL, id, id) = (void*)objc_msgSendSuper;
		super_class(&super, @selector(connection:didReceiveData:), connection, data);
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self __dtx_appendAttachedData:data];
	
	if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:_cmd])
	{
		struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
		void (*super_class)(struct objc_super*, SEL, id, id) = (void*)objc_msgSendSuper;
		super_class(&super, _cmd, connection, data);
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if([[self dtx_attachedObjectForKey:__DTXConnectionDidFail] boolValue] == NO)
	{
		__DTXProfilerMarkNetworkResponseEnd([self dtx_attachedObjectForKey:__DTXConnectionResponse], [self dtx_attachedObjectForKey:__DTXConnectionData], nil, [connection dtx_attachedObjectForKey:__DTXConnectionUnique], NSDate.date);
	}
	
	if([class_getSuperclass(object_getClass(self)) instancesRespondToSelector:_cmd])
	{
		struct objc_super super = {.receiver = self, .super_class = class_getSuperclass(object_getClass(self))};
		void (*super_class)(struct objc_super*, SEL, id) = (void*)objc_msgSendSuper;
		super_class(&super, _cmd, connection);
	}
}

@end

@interface NSURLConnection ()

- (id)_initWithRequest:(id)arg1 delegate:(id)arg2 usesCache:(_Bool)arg3 maxContentLength:(long long)arg4 startImmediately:(_Bool)arg5 connectionProperties:(id)arg6;

@end

static void __copyMethods(Class orig, Class target)
{
	//Copy class methods
	Class targetMetaclass = object_getClass(target);
	
	unsigned int methodCount = 0;
	Method *methods = class_copyMethodList(object_getClass(orig), &methodCount);
	
	for (unsigned int i = 0; i < methodCount; i++)
	{
		Method method = methods[i];
		if(strcmp(sel_getName(method_getName(method)), "load") == 0 || strcmp(sel_getName(method_getName(method)), "initialize") == 0)
		{
			continue;
		}
		class_addMethod(targetMetaclass, method_getName(method), method_getImplementation(method), method_getTypeEncoding(method));
	}
	
	free(methods);
	
	//Copy instance methods
	methods = class_copyMethodList(orig, &methodCount);
	
	for (unsigned int i = 0; i < methodCount; i++)
	{
		Method method = methods[i];
		class_addMethod(target, method_getName(method), method_getImplementation(method), method_getTypeEncoding(method));
	}
	
	free(methods);
}


@implementation NSURLConnection (DTXLegacyConnectionRecording)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Method m1 = class_getInstanceMethod(self.class, @selector(_initWithRequest:delegate:usesCache:maxContentLength:startImmediately:connectionProperties:));
		Method m2 = class_getInstanceMethod(self.class, @selector(_initWithRequest___dtx:delegate:usesCache:maxContentLength:startImmediately:connectionProperties:));
		
		method_exchangeImplementations(m1, m2);
	});
}

- (id)_initWithRequest___dtx:(NSURLRequest*)arg1 delegate:(id<NSURLConnectionDelegate>)origDelegate usesCache:(BOOL)arg3 maxContentLength:(long long)arg4 startImmediately:(BOOL)arg5 connectionProperties:(id)arg6
{
	if(origDelegate != nil && [origDelegate respondsToSelector:@selector(__dtx_net_canaryInTheCoalMine)] == NO)
	{
		NSString* clsName = [NSString stringWithFormat:@"%@(%@)", NSStringFromClass([origDelegate class]), NSStringFromClass(__DTX_DelegateProxy.class)];
		Class cls = objc_getClass(clsName.UTF8String);
		
		if(cls == nil)
		{
			cls = objc_allocateClassPair(origDelegate.class, clsName.UTF8String, 0);
			__copyMethods([__DTX_DelegateProxy class], cls);
			objc_registerClassPair(cls);
		}
		
		object_setClass(origDelegate, cls);
	}
	
	if(origDelegate == nil)
	{
		origDelegate = [__DTX_DelegateProxy new];
	}
	
	NSMutableURLRequest* arg1_ = [arg1 mutableCopy];
	
	DTXProfilingConfiguration* config = __DTXProfilerGetActiveConfiguration();
	if(config != nil && config.disableNetworkCache == YES)
	{
		arg1_.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	}
	
	self = [self _initWithRequest___dtx:arg1_ delegate:origDelegate usesCache:arg3 maxContentLength:arg4 startImmediately:arg5 connectionProperties:arg6];
	
	[self dtx_attachObject:[NSProcessInfo processInfo].globallyUniqueString forKey:__DTXConnectionUnique];
	
	return self;
}

@end
