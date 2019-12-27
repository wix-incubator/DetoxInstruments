//
//  DTXRemoteProfilingManager.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <pthread.h>

#import "DTXRemoteProfilingManager.h"
#import "DTXRemoteProfilingConnectionManager.h"
#import "DTXProfiler-Private.h"
#import "DTXProfilingConfiguration-Private.h"

DTX_CREATE_LOG(RemoteProfilingManager);

static DTXRemoteProfilingManager* __sharedManager;
static DTXRemoteProfilingManager* __privateLaunchProfilingManager;

@interface DTXRemoteProfilingManager () <NSNetServiceDelegate, DTXRemoteProfilingConnectionManagerDelegate>

@end

@implementation DTXRemoteProfilingManager
{
	NSNetService* _publishingService;
	BOOL _currentlyPublished;
	
	pthread_mutex_t _connectionsMutex;
	NSMutableArray<DTXRemoteProfilingConnectionManager*>* _connections;
	
	NSURL* _pendingAppLaunchProfilingRecording;
}

+ (void)load
{
	@autoreleasepool
	{
		//Start a remote profiling manager.
		__sharedManager = [DTXRemoteProfilingManager new];
		
		NSDictionary* pendingLaunchProfile = [NSUserDefaults.standardUserDefaults objectForKey:@"_dtxprofiler_pendingLaunchProfiling"];
		[NSUserDefaults.standardUserDefaults removeObjectForKey:@"_dtxprofiler_pendingLaunchProfiling"];
		[NSUserDefaults.standardUserDefaults synchronize];
		if(pendingLaunchProfile)
		{
			NSString* session = pendingLaunchProfile[@"session"];
			NSTimeInterval duration = [pendingLaunchProfile[@"duration"] doubleValue];
			NSDictionary* configDict = pendingLaunchProfile[@"config"];
			
			__privateLaunchProfilingManager = [[DTXRemoteProfilingManager alloc] initWithServiceType:@"_detoxprofiling_launchprofiling._tcp" name:session];
			
			if(duration == 0)
			{
				duration = 15.0;
			}
			
			DTXMutableProfilingConfiguration* config = configDict == nil ? [DTXMutableProfilingConfiguration defaultProfilingConfiguration] : [[DTXMutableProfilingConfiguration alloc] initWithCoder:(id)configDict];
			config.recordingFileURL = [DTXProfilingConfiguration _urlForLaunchRecordingWithSessionID:session];
			
			DTXProfiler* launchProfiler = [DTXProfiler new];
			[launchProfiler startProfilingWithConfiguration:config duration:duration completionHandler:^(NSError * _Nullable error) {
				dtx_defer {
					[__privateLaunchProfilingManager _stopPublishing];
					__privateLaunchProfilingManager = nil;
				};
				
				DTXRemoteProfilingConnectionManager* connection = __privateLaunchProfilingManager._firstConnection;
				if(connection == nil)
				{
					__privateLaunchProfilingManager->_pendingAppLaunchProfilingRecording = config.recordingFileURL;
					return;
				}
				
				[connection sendFinishedLaunchProfilingRecordingWithURL:config.recordingFileURL];

				[NSFileManager.defaultManager removeItemAtURL:config.recordingFileURL error:NULL];
			}];
		}
	}
}

- (void)_applicationInBackground
{
	[self _stopPublishing];
	
	[_connections enumerateObjectsUsingBlock:^(DTXRemoteProfilingConnectionManager * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj.isProfiling)
		{
			return;
		}
		
		[obj abortConnectionAndProfiling];
	}];
}

- (void)_applicationInForeground
{
	[self _stopPublishing];
	[self _resumePublishing];
}

- (instancetype)init
{
	return [self initWithServiceType:@"_detoxprofiling._tcp" name:@""];
}

- (instancetype)initWithServiceType:(NSString*)serviceType name:(NSString*)serviceName
{
	self = [super init];
	
	if(self)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationInBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
		
		pthread_mutexattr_t attr;
		pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&_connectionsMutex, &attr);
		_connections = [NSMutableArray new];
		
		_publishingService = [[NSNetService alloc] initWithDomain:@"local" type:serviceType name:serviceName port:0];
		_publishingService.delegate = self;
		[self _resumePublishing];
	}
	
	return self;
}

- (void)_resumePublishing
{
	void (^resumePublish)(void) = ^ {
		if(self->_currentlyPublished)
		{
			return;
		}
		
		dtx_log_info(@"Attempting to publish service of type “%@”", self->_publishingService.type);
		[self->_publishingService publishWithOptions:NSNetServiceListenForConnections];
		self->_currentlyPublished = YES;
	};
	
	if(NSThread.isMainThread)
	{
		resumePublish();
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), resumePublish);
}

- (void)_stopPublishing
{
	void (^stopPublish)(void) = ^ {
		self->_currentlyPublished = NO;
		[self->_publishingService stop];
	};
	
	if(NSThread.isMainThread)
	{
		stopPublish();
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), stopPublish);
}

- (DTXRemoteProfilingConnectionManager*)_firstConnection
{
	pthread_mutex_lock_deferred_unlock(&_connectionsMutex);
	return _connections.firstObject;
}

#pragma mark NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
	dtx_log_error(@"Error publishing service of type “%@”: %@", _publishingService.type, errorDict);
	[sender stop];
	
	//Retry in 10 seconds.
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self _resumePublishing];
	});
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
	dtx_log_info(@"Accepted connection for service of type “%@”", sender.type);
	auto connectionManager = [[DTXRemoteProfilingConnectionManager alloc] initWithInputStream:inputStream outputStream:outputStream];
	connectionManager.delegate = self;
	
	pthread_mutex_lock_deferred_unlock(&_connectionsMutex);
	[_connections addObject:connectionManager];
	
	if(_pendingAppLaunchProfilingRecording)
	{
		//If by any chance we have an already finished app launch recording, send it to Detox Instruments.
		[connectionManager sendFinishedLaunchProfilingRecordingWithURL:_pendingAppLaunchProfilingRecording];
		[NSFileManager.defaultManager removeItemAtURL:_pendingAppLaunchProfilingRecording error:NULL];
		_pendingAppLaunchProfilingRecording = nil;
	}
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	dtx_log_info(@"Net service of type “%@” published", sender.type);
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	dtx_log_info(@"Net service of type “%@” stopped", sender.type);
}

#pragma DTXRemoteProfilingConnectionManagerDelegate

- (void)remoteProfilingConnectionManager:(DTXRemoteProfilingConnectionManager*)manager didFinishWithError:(NSError*)error
{
	[manager abortConnectionAndProfiling];
	
	pthread_mutex_lock_deferred_unlock(&_connectionsMutex);
	[_connections removeObject:manager];
	
	[self _resumePublishing];
}

- (void)remoteProfilingConnectionManagerDidStartProfiling:(DTXRemoteProfilingConnectionManager*)manager
{
	[self _stopPublishing];
	
	pthread_mutex_lock_deferred_unlock(&_connectionsMutex);
	for(DTXRemoteProfilingConnectionManager* connection in _connections)
	{
		if(connection == manager)
		{
			continue;
		}
		
		[connection abortConnectionAndProfiling];
	}
	_connections = @[manager].mutableCopy;
}

@end
