//
//  DTXRemoteProfilingManager.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DTXRemoteProfilingManager.h"
#import "DTXRemoteProfilingConnectionManager.h"

DTX_CREATE_LOG(RemoteProfilingManager);

static DTXRemoteProfilingManager* __sharedManager;

@interface DTXRemoteProfilingManager () <NSNetServiceDelegate, DTXRemoteProfilingConnectionManagerDelegate>

@end

@implementation DTXRemoteProfilingManager
{
	NSNetService* _publishingService;
	DTXRemoteProfilingConnectionManager* _connectionManager;
}

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		//Start a remote profiling manager.
		__sharedManager = [DTXRemoteProfilingManager new];
	});
}

- (void)_applicationDidEnterForeground
{
	[_publishingService stop];
	[self _resumePublishing];
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
		
		_publishingService = [[NSNetService alloc] initWithDomain:@"local" type:@"_detoxprofiling._tcp" name:@"" port:0];
		_publishingService.delegate = self;
		[self _resumePublishing];
	}
	
	return self;
}

- (void)_resumePublishing
{
	if(_connectionManager)
	{
		return;
	}
	
	dtx_log_info(@"Attempting to publish “%@” service", _publishingService.type);
	[_publishingService publishWithOptions:NSNetServiceListenForConnections];
}

- (void)_errorOutWithError:(NSError*)error
{
	[_connectionManager abortConnectionAndProfiling];
	[self _resumePublishing];
}

#pragma mark NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
	dtx_log_error(@"Error publishing service: %@", errorDict);
	[sender stop];
	
	//Retry in 10 seconds.
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self _resumePublishing];
	});
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
	if(_connectionManager != nil)
	{
		dtx_log_debug(@"Ignoring additional connection");
		return;
	}
	
	dtx_log_info(@"Accepted connection");
	_connectionManager = [[DTXRemoteProfilingConnectionManager alloc] initWithInputStream:inputStream outputStream:outputStream];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[sender stop];
	});
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	dtx_log_info(@"Net service published");
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	dtx_log_info(@"Net service stopped");
}

#pragma DTXRemoteProfilingConnectionManagerDelegate

- (void)remoteProfilingConnectionManager:(DTXRemoteProfilingConnectionManager*)manager didFinishWithError:(NSError*)error
{
	[self _errorOutWithError:error];
}

@end
