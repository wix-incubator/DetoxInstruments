//
//  DTXRemoteProfilingTarget.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteProfilingTarget-Private.h"
#import "DTXRemoteProfilingBasics.h"
#import "DTXProfilingConfiguration.h"
#import "AutoCoding.h"

@interface DTXRemoteProfilingTarget () <DTXSocketConnectionDelegate>
{
	dispatch_source_t _pingTimer;
	NSDate* _lastPingDate;
}

@property (nonatomic, strong, readwrite) DTXSocketConnection* connection;

@end

@implementation DTXRemoteProfilingTarget

+ (NSData*)_dataForNetworkCommand:(NSDictionary*)cmd
{
	return [NSPropertyListSerialization dataWithPropertyList:cmd format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
}

+ (NSDictionary*)_responseFromNetworkData:(NSData*)data
{
	return [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
}

- (void)_writeCommand:(NSDictionary*)cmd completionHandler:(void (^)(void))completionHandler
{
	completionHandler = completionHandler ?: ^ () {};
	
	__weak __auto_type weakSelf = self;
	
	[self.connection writeData:[DTXRemoteProfilingTarget _dataForNetworkCommand:cmd] completionHandler:^(NSError * _Nullable error) {
		if(error) {
			[weakSelf _errorOutWithError:error];
			return;
		}
		
		completionHandler();
	}];
}

- (void)_readCommandWithCompletionHandler:(void (^)(NSDictionary *cmd))completionHandler
{
	completionHandler = completionHandler ?: ^ (NSDictionary* d) {};
	
	__weak __auto_type weakSelf = self;
	
	[self.connection readDataWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
		if(data == nil)
		{
			[weakSelf _errorOutWithError:error];
			return;
		}
		
		NSDictionary* dict = [DTXRemoteProfilingTarget _responseFromNetworkData:data];
		
		completionHandler(dict);
	}];
}

- (void)_connectWithHostName:(NSString*)hostName port:(NSInteger)port workQueue:(dispatch_queue_t)workQueue
{
	_hostName = hostName;
	_port = port;
	_workQueue = workQueue;
	
	_state = DTXRemoteProfilingTargetStateResolved;
	
	self.connection = [[DTXSocketConnection alloc] initWithHostName:hostName port:port queue:_workQueue];
	self.connection.delegate = self;
	
	[self.connection open];
	
	__block dispatch_source_t pingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _workQueue);
	_pingTimer = pingTimer;
	uint64_t interval = 2.0 * NSEC_PER_SEC;
	dispatch_source_set_timer(_pingTimer, dispatch_walltime(NULL, 0), interval, interval / 10);
	
	__weak __auto_type weakSelf = self;
	dispatch_source_set_event_handler(_pingTimer, ^ {
		__strong __typeof(weakSelf) strongSelf = weakSelf;
		
		if(strongSelf == nil)
		{
			dispatch_cancel(pingTimer);
			pingTimer = nil;
			
			return;
		}
		
		[strongSelf _sendPing];
	});
	
	dispatch_resume(_pingTimer);
	
	[self _readNextCommand];
}

- (void)_sendPing
{
	__weak __auto_type weakSelf = self;
	
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypePing)} completionHandler:^()
	{
		__strong __typeof(weakSelf) strongSelf = weakSelf;
		
		if(strongSelf == nil)
		{
			return;
		}
		
		strongSelf->_lastPingDate = [NSDate date];
	}];
}

- (void)_errorOutWithError:(NSError*)error
{
	if(_pingTimer != nil)
	{
		dispatch_cancel(_pingTimer);
	}
	_pingTimer = nil;
	
	_connection.delegate = nil;
	_connection = nil;
	
	[self.delegate connectionDidCloseForProfilingTarget:self];
}

- (void)_readNextCommand
{
	__weak __auto_type weakSelf = self;
	
	[self _readCommandWithCompletionHandler:^(NSDictionary *cmd)
	{
		switch ((DTXRemoteProfilingCommandType)[cmd[@"cmdType"] unsignedIntegerValue]) {
			case DTXRemoteProfilingCommandTypeGetDeviceInfo:
				[weakSelf _handleDeviceInfo:cmd];
				break;
			case DTXRemoteProfilingCommandTypeProfilingStoryEvent:
				[weakSelf _handleProfilerStoryEvent:cmd];
				break;
			case DTXRemoteProfilingCommandTypeStopProfiling:
				[weakSelf _handleRecordingDidStop:cmd];
			case DTXRemoteProfilingCommandTypePing:
				break;
			default:
				break;
		}
		
		[weakSelf _readNextCommand];
	}];
}

- (void)_handleDeviceInfo:(NSDictionary*)deviceInfo
{
	self.deviceName = deviceInfo[@"deviceName"];
	self.appName = deviceInfo[@"appName"];
	self.deviceOS = deviceInfo[@"deviceOS"];
	self.deviceInfo = deviceInfo;
	
	_state = DTXRemoteProfilingTargetStateDeviceInfoLoaded;
	
	[self.delegate profilingTargetDidLoadDeviceInfo:self];
}

- (void)_handleProfilerStoryEvent:(NSDictionary*)storyEvent
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.storyDecoder willDecodeStoryEvent];
		
		SEL cmd = NSSelectorFromString([NSString stringWithFormat:@"%@entityDescription:", storyEvent[@"selector"]]);
		NSDictionary* object = storyEvent[@"object"];
		NSArray* additionalParams = storyEvent[@"additionalParams"];
		NSString* entityName = storyEvent[@"entityName"];
		NSEntityDescription* entityDescription = _managedObjectContext.persistentStoreCoordinator.managedObjectModel.entitiesByName[entityName];
		
		NSMethodSignature* sig = [(id)self.storyDecoder methodSignatureForSelector:cmd];
		if(sig == nil)
		{
			return;
		}
		
		NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
		invocation.target = self.storyDecoder;
		invocation.selector = cmd;
		[invocation retainArguments];
		[invocation setArgument:&object atIndex:2];
		__block NSUInteger argIdx = 3;
		[additionalParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[invocation setArgument:&obj atIndex:argIdx++];
		}];
		[invocation setArgument:&entityDescription atIndex:argIdx];
		
		[invocation invoke];
		
		[self.storyDecoder didDecodeStoryEvent];
	});
}

- (void)_handleRecordingDidStop:(NSDictionary*)storyEvent
{
	
}

- (void)loadDeviceInfo
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeGetDeviceInfo)} completionHandler:nil];
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeStartProfilingWithConfiguration), @"configuration": configuration.dictionaryRepresentation} completionHandler:nil];
}

- (void)addTagWithName:(NSString*)name
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeAddTag), @"name": name} completionHandler:nil];
}

- (void)stopProfiling
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeStopProfiling)} completionHandler:nil];
}

#pragma mark DTXSocketConnectionDelegate

- (void)readClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	[self _errorOutWithError:nil];
}

- (void)writeClosedForSocketConnection:(DTXSocketConnection*)socketConnection
{
	[self _errorOutWithError:nil];
}

@end
