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
#import "DTXRemoteProfilingBasics.h"
#import "DTXDeviceInfo.h"
#import "DTXFileSystemItem.h"
#import "AutoCoding.h"

DTX_CREATE_LOG(RemoteProfilingManager);

static DTXRemoteProfilingManager* __sharedManager;

@interface DTXRemoteProfilingManager () <NSNetServiceDelegate, DTXSocketConnectionDelegate, DTXRemoteProfilerDelegate>

@end

@implementation DTXRemoteProfilingManager
{
	NSNetService* _publishingService;
	DTXSocketConnection* _connection;
	DTXRemoteProfiler* _remoteProfiler;
	dispatch_source_t _pingCheckerTimer;
	NSDate* _lastPingDate;
}

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		//Start a remote profiling manager.
		__sharedManager = [DTXRemoteProfilingManager new];
	});
}

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
	
	[_connection writeData:[DTXRemoteProfilingManager _dataForNetworkCommand:cmd] completionHandler:^(NSError * _Nullable error) {
		if(error) {
			[self _errorOutWithError:error];
			return;
		}
		
		completionHandler();
	}];
}

- (void)_readCommandWithCompletionHandler:(void (^)(NSDictionary *cmd))completionHandler
{
	completionHandler = completionHandler ?: ^ (NSDictionary* d) {};
	
	[_connection readDataWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
		if(data == nil)
		{
			[self _errorOutWithError:error];
			return;
		}
		
		NSDictionary* dict = [DTXRemoteProfilingManager _responseFromNetworkData:data];
		
		completionHandler(dict);
	}];
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
	if(_remoteProfiler != nil)
	{
		return;
	}
	
	dtx_log_info(@"Attempting to publish “%@” service", _publishingService.type);
	[_publishingService publishWithOptions:NSNetServiceListenForConnections];
}

- (void)_errorOutWithError:(NSError*)error
{
	if(_pingCheckerTimer != nil)
	{
		dispatch_cancel(_pingCheckerTimer);
	}
	_pingCheckerTimer = nil;
	
	[_remoteProfiler stopProfilingWithCompletionHandler:nil];
	_remoteProfiler = nil;
	[self _resumePublishing];
}

- (void)_sendPing
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypePing)} completionHandler:^()
	 {
		 _lastPingDate = [NSDate date];
	 }];
	
}

#pragma mark Socket Commands

- (void)_nextCommand
{
	[self _readCommandWithCompletionHandler:^(NSDictionary *cmd) {
		DTXRemoteProfilingCommandType cmdType = [cmd[@"cmdType"] unsignedIntegerValue];
		switch (cmdType) {
			case DTXRemoteProfilingCommandTypePing:
			{
				_lastPingDate = [NSDate date];
			}	break;
			case DTXRemoteProfilingCommandTypeGetDeviceInfo:
			{
				[self _sendDeviceInfo];
			} 	break;
			case DTXRemoteProfilingCommandTypeStartProfilingWithConfiguration:
			{
				NSDictionary* configDict = cmd[@"configuration"];
				DTXProfilingConfiguration* config = configDict == nil ? [DTXProfilingConfiguration defaultProfilingConfiguration] : [[DTXProfilingConfiguration alloc] initWithCoder:(id)configDict];
				_remoteProfiler = [[DTXRemoteProfiler alloc] initWithOpenedSocketConnection:_connection remoteProfilerDelegate:self];
				[_remoteProfiler startProfilingWithConfiguration:config];
			}	break;
			case DTXRemoteProfilingCommandTypeAddTag:
			{
				NSString* name = cmd[@"name"];
				[_remoteProfiler addTag:name];
			}	break;
			case DTXRemoteProfilingCommandTypePushGroup:
			{
				NSString* name = cmd[@"name"];
				[_remoteProfiler pushSampleGroupWithName:name];
			}	break;
			case DTXRemoteProfilingCommandTypePopGroup:
			{
				[_remoteProfiler popSampleGroup];
			}	break;
			case DTXRemoteProfilingCommandTypeStopProfiling:
			{
				[_remoteProfiler stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
					[self _sendRecordingDidStop];
				}];
				_remoteProfiler = nil;
			}	break;
			case DTXRemoteProfilingCommandTypeGetContainerContents:
			{
				[self _sendContainerContents];
				
			}	break;
			case DTXRemoteProfilingCommandTypeDownloadContainer:
			{
				NSURL* URL = [NSURL fileURLWithPath:cmd[@"URL"]];
				[self _sendContainerContentsZipWithURL:URL];
				
			}	break;
			case DTXRemoteProfilingCommandTypeDeleteContainerIten:
			{
				NSURL* URL = [NSURL fileURLWithPath:cmd[@"URL"]];
				[self _deleteContainerItemWithURL:URL];
			}	break;
			case DTXRemoteProfilingCommandTypeProfilingStoryEvent:
			{
				NSAssert(NO, @"Should not be here.");
			}	break;
		}
		
		[self _nextCommand];
	}];
}

- (void)_sendDeviceInfo
{
	NSMutableDictionary* cmd = [[DTXDeviceInfo deviceInfoDictionary] mutableCopy];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeGetDeviceInfo);
	
//	dispatch_group_t group = dispatch_group_create();
//	__unused __block NSData* screenImageData = nil;
//
//	dispatch_group_enter(group);
//
//	dispatch_async(dispatch_get_main_queue(), ^{
//		UIView* view = [UIScreen.mainScreen snapshotViewAfterScreenUpdates:YES];
//
//		UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, UIScreen.mainScreen.scale);
//
//		[view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
//
//		CGContextRef context = UIGraphicsGetCurrentContext();
//		
//		UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
//
//		if (orientation == UIInterfaceOrientationLandscapeLeft)
//		{
//			CGContextRotateCTM (context, 90.0 * M_PI / 180.0);
//		}
//		else if (orientation == UIInterfaceOrientationLandscapeRight)
//		{
//			CGContextRotateCTM (context, -90.0 * M_PI / 180.0);
//		}
//		else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
//		{
//			CGContextRotateCTM (context, 180.0 * M_PI / 180.0);
//		}
//
//		__unused UIImage *saver = UIGraphicsGetImageFromCurrentImageContext();
//
//		UIGraphicsEndImageContext();
//
//		screenImageData = UIImageJPEGRepresentation(saver, 0.5);
//
//		dispatch_group_leave(group);
//	});
//
//	dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)));
//
//	if(screenImageData != nil)
//	{
//		cmd[@"snapshot"] = screenImageData;
//	}
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_sendContainerContents
{
	NSURL* baseDataURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@".."] URLByStandardizingPath];
	DTXFileSystemItem* rootItem = [[DTXFileSystemItem alloc] initWithFileURL:baseDataURL];
	
	NSMutableDictionary* cmd = [NSMutableDictionary new];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeGetContainerContents);
	cmd[@"containerContents"] = [NSKeyedArchiver archivedDataWithRootObject:rootItem];
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_deleteContainerItemWithURL:(NSURL*)URL
{
	if(URL != nil)
	{
		[[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
	}
}

- (void)_sendContainerContentsZipWithURL:(NSURL*)URL
{
	NSURL* baseDataURL = URL;
	if(baseDataURL == nil)
	{
		baseDataURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@".."] URLByStandardizingPath];
	}
		
	DTXFileSystemItem* rootItem = [[DTXFileSystemItem alloc] initWithFileURL:baseDataURL];
	
	NSMutableDictionary* cmd = [NSMutableDictionary new];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeDownloadContainer);
	cmd[@"containerContents"] = rootItem.isDirectory ? rootItem.zipContents : rootItem.contents;
	cmd[@"wasZipped"] = @(rootItem.isDirectory);
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_sendRecordingDidStop
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeStopProfiling)} completionHandler:nil];
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
	
	__block dispatch_source_t pingCheckerTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _connection.workQueue);
	_pingCheckerTimer = pingCheckerTimer;
	uint64_t interval = 3 * NSEC_PER_SEC;
	dispatch_source_set_timer(_pingCheckerTimer, dispatch_walltime(NULL, 0), interval, interval / 10);
	
	__weak __typeof(self) weakSelf = self;
	dispatch_source_set_event_handler(_pingCheckerTimer, ^ {
		__strong __typeof(weakSelf) strongSelf = weakSelf;
		
		if(strongSelf == nil)
		{
			dispatch_cancel(pingCheckerTimer);
			pingCheckerTimer = nil;
			
			return;
		}
		
		[strongSelf _sendPing];
	});
	
	dispatch_resume(_pingCheckerTimer);
	
	[self _nextCommand];
	
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

#pragma mark DTXRemoteProfilerDelegate

- (void)remoteProfiler:(DTXRemoteProfiler *)remoteProfiler didFinishWithError:(NSError *)error
{
	if(error)
	{
		dtx_log_error(@"Remote profiler finished with error: %@", error);
	}
	else
	{
		dtx_log_info(@"Remote profiler finished");
	}
	
	[self _errorOutWithError:error];
}

#pragma mark DTXSocketConnectionDelegate

- (void)readClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	[socketConnection closeWrite];
	
	dtx_log_info(@"Socket connection closed for reading");

	[self _errorOutWithError:nil];
}

- (void)writeClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	[socketConnection closeRead];
	
	dtx_log_info(@"Socket connection closed for writing");
	
	[self _errorOutWithError:nil];
}

@end
