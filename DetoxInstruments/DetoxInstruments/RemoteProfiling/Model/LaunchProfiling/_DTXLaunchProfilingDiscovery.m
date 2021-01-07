//
//  _DTXLaunchProfilingDiscovery.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/1/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "_DTXLaunchProfilingDiscovery.h"
#import "DTXRemoteTarget-Private.h"

@interface _DTXLaunchProfilingDiscovery () <NSNetServiceBrowserDelegate, NSNetServiceDelegate> @end

@implementation _DTXLaunchProfilingDiscovery
{
	NSString* _name;
	void (^_completionHandler)(DTXRemoteTarget* target);
	
	NSNetServiceBrowser* _browser;
	NSNetService* _targetService;
}

- (instancetype)initWithSessionID:(NSString*)session completionHandler:(void(^)(DTXRemoteTarget* target))completionHandler
{
	self = [super init];
	
	if(self)
	{
		_name = session;
		_completionHandler = completionHandler;
		
		_browser = [NSNetServiceBrowser new];
		_browser.delegate = self;
		
		[_browser searchForServicesOfType:@"_detoxprofiling_launchprofiling._tcp" inDomain:@""];
	}
	
	return self;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	if([service.name isEqualToString:_name] == NO || _targetService != nil)
	{
		return;
	}
	
	_targetService = service;
	_targetService.delegate = self;
	
	[_targetService resolveWithTimeout:2];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	DTXRemoteTarget* target = [DTXRemoteTarget new];
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
	[target _connectWithHostName:sender.hostName port:sender.port workQueue:dtx_dispatch_queue_create_autoreleasing("com.wix.DTXRemoteProfiler", qosAttribute)];
	
	_completionHandler(target);
	_completionHandler = nil;
}

- (void)stop
{
	[_browser stop];
	[_targetService stop];
	_completionHandler = nil;
}

@end
