//
//  DTXNetworkRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXNetworkRecorder.h"
#import "DBURLProtocol.h"

@interface DTXNetworkRecorder ()

@end

static NSMutableArray<id<DTXNetworkListener>>* _networkListeners;
static dispatch_queue_t _networkListenersQueue;

@implementation DTXNetworkRecorder

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_networkListeners = [NSMutableArray new];
		_networkListenersQueue = dispatch_queue_create("com.wix.DTXProfilerNetworkListenersQueue", DISPATCH_QUEUE_SERIAL);
		DBURLProtocol.delegate = (id)self;
	});
}

+ (void)addNetworkListener:(id<DTXNetworkListener>)listener
{
	dispatch_sync(_networkListenersQueue, ^{
		[_networkListeners addObject:listener];
		
		if(_networkListeners.count == 1)
		{
			[NSURLProtocol registerClass:[DBURLProtocol class]];
		}
	});
}

+ (void)removeNetworkListener:(id<DTXNetworkListener>)listener
{
	dispatch_sync(_networkListenersQueue, ^{
		[_networkListeners removeObject:listener];
		
		if(_networkListeners.count == 0)
		{
			[NSURLProtocol unregisterClass:[DBURLProtocol class]];
		}
	});
}

#pragma mark DBURLProtocolDelegate

+ (void)urlProtocol:(DBURLProtocol*)protocol didStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier
{
	dispatch_sync(_networkListenersQueue, ^{
		[_networkListeners enumerateObjectsUsingBlock:^(id<DTXNetworkListener>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj networkRecorderDidStartRequest:request uniqueIdentifier:uniqueIdentifier];
		}];
	});
}

+ (void)urlProtocol:(DBURLProtocol*)protocol didFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier
{
	dispatch_sync(_networkListenersQueue, ^{
		[_networkListeners enumerateObjectsUsingBlock:^(id<DTXNetworkListener>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj netwrokRecorderDidFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier];
		}];
	});
}

@end
