//
//  DTXRemoteLaunchProfilingClient.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/1/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRemoteLaunchProfilingClient.h"
#import "_DTXLaunchProfilingDiscovery.h"
#import "DTXRemoteTarget-Private.h"

@interface DTXRemoteLaunchProfilingClient () <DTXRemoteTargetDelegate>

@end

@implementation DTXRemoteLaunchProfilingClient
{
	NSString* _session;
	_DTXLaunchProfilingDiscovery* _discovery;
	DTXRemoteTarget* _target;
}

- (instancetype)initWithLaunchProfilingSessionID:(NSString *)session
{
	self = [super init];
	
	if(self)
	{
		_session = session;
	}
	
	return self;
}

- (void)startConnecting
{
	_discovery = [[_DTXLaunchProfilingDiscovery alloc] initWithSessionID:_session completionHandler:^(DTXRemoteTarget *target) {
		_target = target;
		_target.delegate = self;
		
		[self.delegate remoteLaunchProfilingClientDidConnect:self];
	}];
}

- (void)stop
{
	[_discovery stop];
}

- (void)profilingTargetDidLoadDeviceInfo:(DTXRemoteTarget*)target
{
	
}

- (void)profilingTarget:(DTXRemoteTarget*)target didFinishLaunchProfilingWithZippedData:(NSData*)zippedData
{
	[self.delegate remoteLaunchProfilingClient:self didFinishLaunchProfilingWithZippedData:zippedData];
}

@end
