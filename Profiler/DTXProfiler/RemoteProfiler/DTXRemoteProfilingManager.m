//
//  DTXRemoteProfilingManager.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DTXRemoteProfilingManager.h"
#import "DTXSocketConnection.h"
#import "DTXRemoteProfiler.h"
#import "DBBuildInfoProvider.h"
#import "DTXRemoteProfilingBasics.h"

DTX_CREATE_LOG(RemoteProfilingManager);

__unused static NSDictionary* __DTXDeviceDetails()
{
	DBBuildInfoProvider* buildProvider = [DBBuildInfoProvider new];
	
	NSDictionary* dataForName = @{@"osType": @0, @"appName": buildProvider.applicationDisplayName, @"deviceName": [UIDevice currentDevice].name, @"osVersion": NSProcessInfo.processInfo.operatingSystemVersionString};
	
	return dataForName;
}

static DTXRemoteProfilingManager* __sharedManager;

@interface DTXRemoteProfilingManager () <NSNetServiceDelegate, DTXSocketConnectionDelegate, DTXRemoteProfilerDelegate>

@end

@implementation DTXRemoteProfilingManager
{
	NSNetService* _publishingService;
	DTXSocketConnection* _connection;
	DTXRemoteProfiler* _remoteProfiler;
}

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		//Start a remote profiling manager.
		__sharedManager = [DTXRemoteProfilingManager new];
	});
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_publishingService = [[NSNetService alloc] initWithDomain:@"local" type:@"_detoxprofiling._tcp" name:@"" port:0];
		_publishingService.delegate = self;
		[self _resumePublishing];
	}
	
	return self;
}

- (void)_resumePublishing
{
	dtx_log_info(@"Attempting to publish “%@” service", _publishingService.type);
	[_publishingService publishWithOptions:NSNetServiceListenForConnections];
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
	if(_remoteProfiler != nil)
	{
		dtx_log_debug(@"Ignoring additional connection");
		return;
	}
	
	dtx_log_info(@"Accepted connection");
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
	_connection = [[DTXSocketConnection alloc] initWithInputStream:inputStream outputStream:outputStream queue:dispatch_queue_create("com.wix.DTXRemoteProfiler", qosAttribute)];
	_connection.delegate = self;
	
	[_connection open];
		
//	_remoteProfiler = [[DTXRemoteProfiler alloc] initWithSocketConnection:_connection remoteProfilerDelegate:self];
	
	[self _nextCommand];
	
	[sender stop];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	dtx_log_info(@"Net service published");
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	dtx_log_info(@"Net service stopped");
}

#pragma mark Socket Commands

- (void)_nextCommand
{
	[_connection readDataWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
		if(data == nil)
		{
			dtx_log_error(@"Unable to read data with error: %@", error);
			//TODO: Decide if soft ignore or drop connection.
			[self _nextCommand];
			return;
		}
		
		NSError* parseErr = nil;
		NSDictionary* cmd = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&parseErr];
		if(cmd == nil)
		{
			dtx_log_error(@"Command read failed with error: %@", parseErr);
			//TODO: Decide if soft ignore or drop connection.
			[self _nextCommand];
			return;
		}
		
		DTXRemoteProfilingCommandType cmdType = [cmd[@"cmdType"] unsignedIntegerValue];
		switch (cmdType) {
			case DTXRemoteProfilingCommandTypeInfo:
				[self _sendDeviceInfo];
				break;
			case DTXRemoteProfilingCommandTypeStartProfiling:
				
				break;
			case DTXRemoteProfilingCommandTypeStopProfiling:
				
				break;
		}
	}];
}

- (void)_sendDeviceInfo
{
	NSDictionary* info = __DTXDeviceDetails();
	NSError* serializeErr = nil;
	NSData* data = [NSPropertyListSerialization dataWithPropertyList:info format:NSPropertyListBinaryFormat_v1_0 options:0 error:&serializeErr];
	if(data == nil)
	{
		dtx_log_error(@"Command write failed with error: %@", serializeErr);
		//TODO: Decide if soft ignore or drop connection.
		return;
	}
	
	[_connection writeData:data completionHandler:^(NSError * _Nullable error) {
		if(error != nil)
		{
			dtx_log_error(@"Unable to write data with error: %@", error);
			//TODO: Decide if soft ignore or drop connection.
			return;
		}
	}];
}

#pragma mark DTXRemoteProfilerDelegate

- (void)remoteProfilerDidFinish:(DTXRemoteProfiler*)remoteProfiler
{
	dtx_log_info(@"Remote profiler finished");
	
	_remoteProfiler = nil;
	[self _resumePublishing];
}

#pragma mark DTXSocketConnectionDelegate

- (void)readClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	[socketConnection closeWrite];
	
	dtx_log_info(@"Socket connection closed for reading");

	[_remoteProfiler stopProfilingWithCompletionHandler:nil];
	[self remoteProfilerDidFinish:_remoteProfiler];
}

- (void)writeClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	[socketConnection closeRead];
	
	dtx_log_info(@"Socket connection closed for writing");
	
	[_remoteProfiler stopProfilingWithCompletionHandler:nil];
	[self remoteProfilerDidFinish:_remoteProfiler];
}

@end
