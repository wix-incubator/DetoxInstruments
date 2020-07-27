//
//  NSURLSessionTask+DTXNetworkRecording.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 10/21/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "NSURLSessionTask+DTXNetworkRecording.h"
#import "DTXProfilerAPI-Private.h"
#import "NSObject+AttachedObjects.h"
@import ObjectiveC;

extern thread_local BOOL _protocolLoading;
static thread_local BOOL _forActualDelegate;

static void* __DTXConnectionUnique = &__DTXConnectionUnique;

static void* __DTXConnectionDidStart = &__DTXConnectionDidStart;
static void* __DTXConnectionDidFail = &__DTXConnectionDidFail;
static void* __DTXConnectionResponse = &__DTXConnectionResponse;
static void* __DTXConnectionData = &__DTXConnectionData;

@interface NSURLSessionTask ()

- (void)resume;
- (void)connection:(id)arg1 didReceiveResponse:(id)arg2 completion:(id)arg3;
- (void)connection:(id)arg1 didFinishLoadingWithError:(id)arg2;
- (void)connection:(id)arg1 didReceiveData:(id)arg2 completion:(id)arg3;
- (void)connection:(id)arg1 didFinishCollectingMetrics:(id)arg2 completion:(id)arg3;
- (id)initWithOriginalRequest:(id)arg1 updatedRequest:(id)arg2 ident:(NSUInteger)arg3 session:(id)arg4;
- (id)initWithOriginalRequest:(id)arg1 ident:(unsigned long)arg2 taskGroup:(id)arg3;

- (void)_onqueue_didFinishCollectingMetrics:(id)arg1 completion:(id)arg2;

@end

@interface NSURLSession ()

- (BOOL)can_delegate_task_didFinishCollectingMetrics;

@end

@implementation NSURLSessionTask (DTXNetworkRecording)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Class cls = NSClassFromString(@"__NSCFLocalDataTask");
		
		NSError* error;
		if([cls instancesRespondToSelector:NSSelectorFromString(@"greyswizzled_resume")])
		{
			DTXSwizzleMethod(cls, NSSelectorFromString(@"greyswizzled_resume"), @selector(__dtx_resume), &error);
		}
		else
		{
			DTXSwizzleMethod(cls, @selector(resume), @selector(__dtx_resume), &error);
		}
		
		DTXSwizzleMethod(cls, @selector(connection:didReceiveResponse:completion:), @selector(__dtx_connection:didReceiveResponse:completion:), &error);
		DTXSwizzleMethod(cls, @selector(connection:didFinishLoadingWithError:), @selector(__dtx_connection:didFinishLoadingWithError:), &error);
		DTXSwizzleMethod(cls, @selector(connection:didReceiveData:completion:), @selector(__dtx_connection:didReceiveData:completion:), &error);
		DTXSwizzleMethod(cls, @selector(connection:didFinishCollectingMetrics:completion:), @selector(__dtx_connection:didFinishCollectingMetrics:completion:), &error);
		if(NO == DTXSwizzleMethod(cls, @selector(initWithOriginalRequest:ident:taskGroup:), @selector(initWithOriginalRequest__dtx:ident:taskGroup:), &error))
		{
			DTXSwizzleMethod(cls, @selector(initWithOriginalRequest:updatedRequest:ident:session:), @selector(initWithOriginalRequest__dtx:updatedRequest:ident:session:), &error);
		}
		DTXSwizzleMethod(cls, @selector(_onqueue_didFinishCollectingMetrics:completion:), @selector(_onqueue_didFinishCollectingMetrics:completion:), &error);
	});
}

- (instancetype)initWithOriginalRequest__dtx:(NSURLRequest*)arg1 ident:(NSUInteger)arg2 taskGroup:(id)arg3
{
	NSMutableURLRequest* arg1_ = [arg1 mutableCopy];
	
	DTXProfilingConfiguration* config = __DTXProfilerGetActiveConfiguration();
	if(config != nil && config.disableNetworkCache == YES)
	{
		arg1_.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	}
		
	return [self initWithOriginalRequest__dtx:arg1_ ident:arg2 taskGroup:arg3];
}

- (instancetype)initWithOriginalRequest__dtx:(NSURLRequest*)arg1 updatedRequest:(NSURLRequest*)arg2 ident:(NSUInteger)arg3 session:(id)arg4;
{
	NSMutableURLRequest* arg1_ = [arg1 mutableCopy];
	NSMutableURLRequest* arg2_ = [arg2 mutableCopy];
	
	DTXProfilingConfiguration* config = __DTXProfilerGetActiveConfiguration();
	if(config != nil && config.disableNetworkCache == YES)
	{
		arg1_.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
		arg2_.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	}
		
	return [self initWithOriginalRequest__dtx:arg1_ updatedRequest:arg2_ ident:arg3 session:arg4];
}

- (void)__dtx_resume
{
	NSString* unique = [NSProcessInfo processInfo].globallyUniqueString;
	
	[self dtx_attachObject:unique forKey:__DTXConnectionUnique];
	
	if(_protocolLoading == NO)
	{
		__DTXProfilerMarkNetworkRequestBegin(self.currentRequest, unique, NSDate.date);
	}
	[self dtx_attachObject:@YES forKey:__DTXConnectionDidStart];
	
	[self __dtx_resume];
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

- (void)__dtx_connection:(id)arg1 didFinishCollectingMetrics:(NSURLSessionTaskMetrics*)arg2 completion:(id)arg3
{
	[self __dtx_connection:arg1 didFinishCollectingMetrics:arg2 completion:arg3];
}

- (void)__dtx_onqueue_didFinishCollectingMetrics:(id)arg1 completion:(id)arg2
{
	_forActualDelegate = YES;
	[self __dtx_onqueue_didFinishCollectingMetrics:arg1 completion:arg2];
	_forActualDelegate = NO;
}

@end
