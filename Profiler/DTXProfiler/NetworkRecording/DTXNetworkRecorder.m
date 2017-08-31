//
//  DTXNetworkRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXNetworkRecorder.h"
#import "DTXURLProtocol.h"
#import "DTXExternalProtocolStorage.h"
@import ObjectiveC;

@interface DTXNetworkRecorder ()

@end

static NSMutableArray<id<DTXNetworkListener>>* __networkListeners;
static dispatch_queue_t __networkListenersQueue;



@implementation DTXNetworkRecorder

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__networkListeners = [NSMutableArray new];
		__networkListenersQueue = dispatch_queue_create("com.wix.DTXProfilerNetworkListenersQueue", DISPATCH_QUEUE_SERIAL);
		
		DTXURLProtocol.delegate = (id)self;
	});
}

+ (BOOL)hasNetworkListeners
{
	__block BOOL rv = NO;
	dispatch_sync(__networkListenersQueue, ^{
		rv = __networkListeners.count > 0;
	});
	
	return rv;
}

+ (void)addNetworkListener:(id<DTXNetworkListener>)listener
{
	dispatch_sync(__networkListenersQueue, ^{
		[__networkListeners addObject:listener];
		
		if(__networkListeners.count == 1)
		{
			[_DTXExternalProtocolStorage setEnabled:YES];
			[NSURLProtocol registerClass:[DTXURLProtocol class]];
		}
	});
}

+ (void)removeNetworkListener:(id<DTXNetworkListener>)listener
{
	dispatch_sync(__networkListenersQueue, ^{
		[__networkListeners removeObject:listener];
		
		if(__networkListeners.count == 0)
		{
			[_DTXExternalProtocolStorage setEnabled:NO];
			[NSURLProtocol unregisterClass:[DTXURLProtocol class]];
		}
	});
}

#pragma mark DBURLProtocolDelegate

+ (void)urlProtocol:(NSURLProtocol*)protocol didStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier
{
	dispatch_sync(__networkListenersQueue, ^{
		[__networkListeners enumerateObjectsUsingBlock:^(id<DTXNetworkListener>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj networkRecorderDidStartRequest:request uniqueIdentifier:uniqueIdentifier];
		}];
	});
}

+ (void)urlProtocol:(NSURLProtocol*)protocol didFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier
{
	dispatch_sync(__networkListenersQueue, ^{
		[__networkListeners enumerateObjectsUsingBlock:^(id<DTXNetworkListener>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj netwrokRecorderDidFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier];
		}];
	});
}

@end
