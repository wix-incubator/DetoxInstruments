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
#import "DTXProfiler-Private.h"
@import ObjectiveC;

@interface DTXNetworkRecorder ()

@end

@implementation DTXNetworkRecorder

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		DTXURLProtocol.delegate = (id)self;
	});
}

#pragma mark NSURLProtocolDelegate

+ (void)urlProtocol:(NSURLProtocol*)protocol didStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier
{
	__DTXProfilerMarkNetworkRequestBegin(request, uniqueIdentifier, NSDate.date);
}

+ (void)urlProtocol:(NSURLProtocol*)protocol didFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier
{
	__DTXProfilerMarkNetworkResponseEnd(response, data, error, uniqueIdentifier, NSDate.date);
}

@end
