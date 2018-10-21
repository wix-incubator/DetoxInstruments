//
//  NSURLSessionTask+DTXNetworkRecording.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 10/21/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSURLSessionTask+DTXNetworkRecording.h"
#import "DTXProfiler-Private.h"
#import "NSObject+AttachedObjects.h"
@import ObjectiveC;

static void* __DTXConnectionUnique = &__DTXConnectionUnique;

static void* __DTXConnectionDidStart = &__DTXConnectionDidStart;
static void* __DTXConnectionDidFail = &__DTXConnectionDidFail;
static void* __DTXConnectionResponse = &__DTXConnectionResponse;
static void* __DTXConnectionData = &__DTXConnectionData;

@interface NSURLSessionTask ()

- (void)_onqueue_resume;
- (void)connection:(id)arg1 didReceiveResponse:(id)arg2 completion:(id)arg3;
- (void)connection:(id)arg1 didFinishLoadingWithError:(id)arg2;
- (void)connection:(id)arg1 didReceiveData:(id)arg2 completion:(id)arg3;
- (id)initWithOriginalRequest:(id)arg1 updatedRequest:(id)arg2 ident:(unsigned long long)arg3 session:(id)arg4;

@end

@implementation NSURLSessionTask (DTXNetworkRecording)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Method m1 = class_getInstanceMethod(NSClassFromString(@"__NSCFLocalSessionTask"), @selector(_onqueue_resume));
		Method m2 = class_getInstanceMethod(self.class, @selector(__dtx__onqueue_resume));
		method_exchangeImplementations(m1, m2);
		
		m1 = class_getInstanceMethod(NSClassFromString(@"__NSCFLocalSessionTask"), @selector(connection:didReceiveResponse:completion:));
		m2 = class_getInstanceMethod(self.class, @selector(__dtx_connection:didReceiveResponse:completion:));
		method_exchangeImplementations(m1, m2);
		
		m1 = class_getInstanceMethod(NSClassFromString(@"__NSCFLocalSessionTask"), @selector(connection:didFinishLoadingWithError:));
		m2 = class_getInstanceMethod(self.class, @selector(__dtx_connection:didFinishLoadingWithError:));
		method_exchangeImplementations(m1, m2);
		
		m1 = class_getInstanceMethod(NSClassFromString(@"__NSCFLocalSessionTask"), @selector(connection:didReceiveData:completion:));
		m2 = class_getInstanceMethod(self.class, @selector(__dtx_connection:didReceiveData:completion:));
		method_exchangeImplementations(m1, m2);
		
		m1 = class_getInstanceMethod(NSClassFromString(@"__NSCFLocalSessionTask"), @selector(initWithOriginalRequest:updatedRequest:ident:session:));
		m2 = class_getInstanceMethod(self.class, @selector(initWithOriginalRequest__dtx:updatedRequest:ident:session:));
		method_exchangeImplementations(m1, m2);
	});
}

- (instancetype)initWithOriginalRequest__dtx:(NSURLRequest*)arg1 updatedRequest:(NSURLRequest*)arg2 ident:(unsigned long long)arg3 session:(id)arg4;
{
	NSMutableURLRequest* arg1_ = [arg1 mutableCopy];
	NSMutableURLRequest* arg2_ = [arg2 mutableCopy];
	
//	arg1_.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
//	arg2_.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	
	return [self initWithOriginalRequest__dtx:arg1_ updatedRequest:arg2_ ident:arg3 session:arg4];
}

- (void)__dtx__onqueue_resume
{
	NSString* unique = [NSProcessInfo processInfo].globallyUniqueString;
	
	[self dtx_attachObject:unique forKey:__DTXConnectionUnique];
	
	__DTXProfilerMarkNetworkRequestBegin(self.currentRequest, unique, NSDate.date);
	[self dtx_attachObject:@YES forKey:__DTXConnectionDidStart];
	
	[self __dtx__onqueue_resume];
}

- (void)__dtx_connection:(id)arg1 didFinishLoadingWithError:(id)arg2;
{
	__DTXProfilerMarkNetworkResponseEnd([self dtx_attachedObjectForKey:__DTXConnectionResponse], [self dtx_attachedObjectForKey:__DTXConnectionData], arg2, [self dtx_attachedObjectForKey:__DTXConnectionUnique], NSDate.date);
	
	[self __dtx_connection:arg1 didFinishLoadingWithError:arg2];
}

- (void)__dtx_connection:(id)arg1 didReceiveResponse:(id)response completion:(id)arg3;
{
	[self dtx_attachObject:[response copy] forKey:__DTXConnectionResponse];
	
	[self __dtx_connection:arg1 didReceiveResponse:response completion:arg3];
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

- (void)__dtx_connection:(id)arg1 didReceiveData:(id)data completion:(id)arg3;
{
	[self __dtx_appendAttachedData:data];
	
	[self __dtx_connection:arg1 didReceiveData:data completion:arg3];
}

@end
