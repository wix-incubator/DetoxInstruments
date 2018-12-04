//
//  DTXRemoteProfilingManager.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <pthread.h>

#import "DTXRemoteProfilingManager.h"
#import "DTXRemoteProfilingConnectionManager.h"

DTX_CREATE_LOG(RemoteProfilingManager);

static DTXRemoteProfilingManager* __sharedManager;

@interface DTXRemoteProfilingManager () <NSNetServiceDelegate, DTXRemoteProfilingConnectionManagerDelegate>

@end

@implementation DTXRemoteProfilingManager
{
	NSNetService* _publishingService;
	BOOL _currentlyPublished;
	
	pthread_mutex_t _connectionsMutex;
	NSMutableArray<DTXRemoteProfilingConnectionManager*>* _connections;
}

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		//Start a remote profiling manager.
		__sharedManager = [DTXRemoteProfilingManager new];
	});
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
	self = [super init];
	
	if(self)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationInBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
		
		pthread_mutexattr_t attr;
		pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&_connectionsMutex, &attr);
		_connections = [NSMutableArray new];
		
		_publishingService = [[NSNetService alloc] initWithDomain:@"local" type:@"_detoxprofiling._tcp" name:@"" port:0];
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
		
		dtx_log_info(@"Attempting to publish “%@” service", self->_publishingService.type);
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
	dtx_log_info(@"Accepted connection");
	auto connectionManager = [[DTXRemoteProfilingConnectionManager alloc] initWithInputStream:inputStream outputStream:outputStream];
	connectionManager.delegate = self;
	
	pthread_mutex_lock(&_connectionsMutex);
	[_connections addObject:connectionManager];
	pthread_mutex_unlock(&_connectionsMutex);
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
	[manager abortConnectionAndProfiling];
	
	pthread_mutex_lock(&_connectionsMutex);
	[_connections removeObject:manager];
	pthread_mutex_unlock(&_connectionsMutex);
	
	[self _resumePublishing];
}

- (void)remoteProfilingConnectionManagerDidStartProfiling:(DTXRemoteProfilingConnectionManager*)manager
{
	[self _stopPublishing];
	
	pthread_mutex_lock(&_connectionsMutex);
	for(DTXRemoteProfilingConnectionManager* connection in _connections)
	{
		if(connection == manager)
		{
			continue;
		}
		
		[connection abortConnectionAndProfiling];
	}
	_connections = @[manager].mutableCopy;
	pthread_mutex_unlock(&_connectionsMutex);
}

@end
