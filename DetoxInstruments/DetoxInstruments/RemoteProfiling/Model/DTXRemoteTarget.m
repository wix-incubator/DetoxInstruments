//
//  DTXRemoteTarget.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteTarget-Private.h"
#import "DTXProfilingBasics.h"
#import "DTXProfilingConfiguration.h"
#import "AutoCoding.h"
#import "DTXViewHierarchySnapshotter.h"

@import AppKit;

@interface DTXRemoteTarget () <DTXSocketConnectionDelegate>
{
	dispatch_source_t _pingTimer;
	NSDate* _lastPingDate;
	
	NSTimer* _uiUpdateTimer;
}

@property (nonatomic, strong, readwrite) DTXSocketConnection* connection;

@end

@implementation DTXRemoteTarget

#pragma mark Connection and Commands

+ (NSData*)_dataForNetworkCommand:(NSDictionary*)cmd
{
	NSData* plist = [NSPropertyListSerialization dataWithPropertyList:cmd format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
	
	NSAssert(plist != nil, @"Unable to encode data to property list.");
	
	return plist;
}

+ (NSDictionary*)_responseFromNetworkData:(NSData*)data
{
	return [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
}

- (void)_writeCommand:(NSDictionary*)cmd completionHandler:(void (^)(void))completionHandler
{
	completionHandler = completionHandler ?: ^ () {};
	
	__weak __auto_type weakSelf = self;
	
	[self.connection writeData:[DTXRemoteTarget _dataForNetworkCommand:cmd] completionHandler:^(NSError * _Nullable error) {
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
		
		NSDictionary* dict = [DTXRemoteTarget _responseFromNetworkData:data];
		
		completionHandler(dict);
	}];
}

- (void)_connectWithHostName:(NSString*)hostName port:(NSInteger)port workQueue:(dispatch_queue_t)workQueue
{
	_hostName = hostName;
	_port = port;
	_workQueue = workQueue;
	
	_state = DTXRemoteTargetStateResolved;
	
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
	
	if([self.delegate respondsToSelector:@selector(connectionDidCloseForProfilingTarget:)])
	{
		[self.delegate connectionDidCloseForProfilingTarget:self];
	}
}

- (void)_readNextCommand
{
	__weak __auto_type weakSelf = self;
	
	[self _readCommandWithCompletionHandler:^(NSDictionary *cmd)
	{
		switch ((DTXRemoteProfilingCommandType)[cmd[@"cmdType"] unsignedIntegerValue]) {
			case DTXRemoteProfilingCommandTypeDownloadContainer:
				[weakSelf _handleDeviceContainerContentsZip:cmd];
				break;
			case DTXRemoteProfilingCommandTypeGetContainerContents:
				[weakSelf _handleDeviceContainerContents:cmd];
				break;
			case DTXRemoteProfilingCommandTypeGetUserDefaults:
				[weakSelf _handleUserDefaults:cmd];
				break;
			case DTXRemoteProfilingCommandTypeGetDeviceInfo:
				[weakSelf _handleDeviceInfo:cmd];
				break;
			case DTXRemoteProfilingCommandTypeLoadScreenSnapshot:
				[weakSelf _handleScreenSnapshot:cmd];
				break;
			case DTXRemoteProfilingCommandTypeProfilingStoryEvent:
				[weakSelf _handleProfilerStoryEvent:cmd];
				break;
			case DTXRemoteProfilingCommandTypeStopProfiling:
				[weakSelf _handleRecordingDidStop:cmd];
			case DTXRemoteProfilingCommandTypePing:
				break;
			case DTXRemoteProfilingCommandTypeGetCookies:
				[weakSelf _handleCookies:cmd];
				break;
			case DTXRemoteProfilingCommandTypeGetPasteboard:
				[weakSelf _handlePasteboard:cmd];
				break;
			case DTXRemoteProfilingCommandTypeCaptureViewHierarchy:
				[weakSelf _handleViewHierarchy:cmd];
				break;
			case DTXRemoteProfilingCommandTypeStartProfilingWithConfiguration:
			case DTXRemoteProfilingCommandTypeAddTag:
			case DTXRemoteProfilingCommandTypePushGroup:
			case DTXRemoteProfilingCommandTypePopGroup:
			case DTXRemoteProfilingCommandTypeDeleteContainerIten:
			case DTXRemoteProfilingCommandTypePutContainerItem:
			case DTXRemoteProfilingCommandTypeChangeUserDefaultsItem:
			case DTXRemoteProfilingCommandTypeSetCookies:
			case DTXRemoteProfilingCommandTypeSetPasteboard:
				break;
		}
		
		[weakSelf _readNextCommand];
	}];
}

#pragma mark Device Info

- (void)loadDeviceInfo
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeGetDeviceInfo)} completionHandler:nil];
}

- (void)loadScreenSnapshot
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeLoadScreenSnapshot)} completionHandler:nil];
}

- (void)_handleDeviceInfo:(NSDictionary*)deviceInfo
{
	self.deviceName = deviceInfo[@"deviceName"];
	self.appName = deviceInfo[@"appName"];
	NSString* marketingName = deviceInfo[@"deviceMarketingName"];
	if(marketingName)
	{
		self.devicePresentable = [NSString stringWithFormat:@"%@, iOS %@", marketingName, [deviceInfo[@"deviceOS"] stringByReplacingOccurrencesOfString:@"Version " withString:@""]];
	}
	else
	{
		self.devicePresentable = [NSString stringWithFormat:@"iOS %@", [deviceInfo[@"deviceOS"] stringByReplacingOccurrencesOfString:@"Version " withString:@""]];
	}
	self.deviceInfo = deviceInfo;
	
	_state = DTXRemoteTargetStateDeviceInfoLoaded;
	
	if([self.delegate respondsToSelector:@selector(profilingTargetDidLoadDeviceInfo:)])
	{
		[self.delegate profilingTargetDidLoadDeviceInfo:self];
	}
	
	if([self.delegate respondsToSelector:@selector(profilingTargetDidLoadScreenSnapshot:)])
	{
		[self loadScreenSnapshot];
	}
}

- (void)_handleScreenSnapshot:(NSDictionary*)deviceSnapshot
{
	self.screenSnapshot = [[NSImage alloc] initWithData:deviceSnapshot[@"screenSnapshot"]];
	
	[_uiUpdateTimer invalidate];
	_uiUpdateTimer = nil;
	
	if([self.delegate respondsToSelector:@selector(profilingTargetDidLoadScreenSnapshot:)])
	{
		[self.delegate profilingTargetDidLoadScreenSnapshot:self];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			__weak auto weakSelf = self;
			_uiUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
				[weakSelf loadScreenSnapshot];
			}];
		});
	}
}

- (BOOL)isCompatibleWithInstruments
{
	NSString* profilerVersion = self.deviceInfo[@"profilerVersion"];
	if(profilerVersion == nil)
	{
		profilerVersion = @"0";
	}
	
	NSString* instrumentsVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	
	return [instrumentsVersion compare:profilerVersion options:NSNumericSearch] != NSOrderedAscending;
}

#pragma mark Container Contents

- (void)loadContainerContents
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeGetContainerContents)} completionHandler:nil];
}

- (void)downloadContainerItemsAtURL:(NSURL*)URL
{
	NSMutableDictionary* cmd = @{@"cmdType": @(DTXRemoteProfilingCommandTypeDownloadContainer)}.mutableCopy;
	if(URL != nil)
	{
		cmd[@"URL"] = URL.path;
	}
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)deleteContainerItemAtURL:(NSURL*)URL
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeDeleteContainerIten), @"URL": URL.path} completionHandler:nil];
}

- (void)putContainerItemAtURL:(NSURL *)URL data:(NSData *)data wasZipped:(BOOL)wasZipped
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypePutContainerItem), @"URL": URL.path, @"contents": data, @"wasZipped": @(wasZipped)} completionHandler:nil];
}

- (void)_handleDeviceContainerContents:(NSDictionary*)containerContents
{
	NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:containerContents[@"containerContents"] error:NULL];
	unarchiver.requiresSecureCoding = NO;
	_containerContents = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	
//	[[NSKeyedArchiver archivedDataWithRootObject:_containerContents] writeToFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/ContainerContents.dat"] atomically:YES];
	
	if([self.delegate respondsToSelector:@selector(profilingTargetdidLoadContainerContents:)])
	{
		[self.delegate profilingTargetdidLoadContainerContents:self];
	}
}

- (void)_handleDeviceContainerContentsZip:(NSDictionary*)containerContents
{
	NSData* containerContentsData = containerContents[@"containerContents"];
	BOOL wasZipped = [containerContents[@"wasZipped"] boolValue];
	
	if([self.delegate respondsToSelector:@selector(profilingTarget:didDownloadContainerContents:wasZipped:)])
	{
		[self.delegate profilingTarget:self didDownloadContainerContents:containerContentsData wasZipped:wasZipped];
	}
}

#pragma mark User Defaults

- (void)loadUserDefaults
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeGetUserDefaults)} completionHandler:nil];
}

- (void)changeUserDefaultsItemWithKey:(NSString*)key changeType:(DTXUserDefaultsChangeType)changeType value:(id)value previousKey:(NSString*)previousKey
{
	NSMutableDictionary* cmd = @{@"cmdType": @(DTXRemoteProfilingCommandTypeChangeUserDefaultsItem)}.mutableCopy;
	cmd[@"type"] = @(changeType);
	cmd[@"key"] = key;
	cmd[@"value"] = value;
	if(previousKey)
	{
		cmd[@"previousKey"] = previousKey;
	}
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_handleUserDefaults:(NSDictionary*)userDefaults
{
	_userDefaults = userDefaults[@"userDefaults"];
	
//	[[NSKeyedArchiver archivedDataWithRootObject:_userDefaults] writeToFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/UserDefaults.dat"] atomically:YES];
	
	if([self.delegate respondsToSelector:@selector(profilingTarget:didLoadUserDefaults:)])
	{
		[self.delegate profilingTarget:self didLoadUserDefaults:self.userDefaults];
	}
}

#pragma mark Cookies

- (void)loadCookies
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeGetCookies)} completionHandler:nil];
}

- (void)_handleCookies:(NSDictionary*)cookies
{
	_cookies = cookies[@"cookies"];
	
//	[[NSKeyedArchiver archivedDataWithRootObject:_cookies] writeToFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/Cookies.dat"] atomically:YES];
	
	if([self.delegate respondsToSelector:@selector(profilingTarget:didLoadCookies:)])
	{
		[self.delegate profilingTarget:self didLoadCookies:self.cookies];
	}
}

- (void)setCookies:(NSArray<NSDictionary<NSString*, id>*>*)cookies
{
	_cookies = [cookies copy];
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeSetCookies), @"cookies": cookies} completionHandler:nil];
}

#pragma mark Pasteboard

- (void)loadPasteboardContents
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeGetPasteboard)} completionHandler:nil];
}

- (void)_handlePasteboard:(NSDictionary*)pasteboard
{
	NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:pasteboard[@"pasteboardContents"] error:NULL];
	unarchiver.requiresSecureCoding = NO;
	_pasteboardContents = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	
//	[[NSKeyedArchiver archivedDataWithRootObject:_pasteboardContents] writeToFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/Pasteboard.dat"] atomically:YES];
	
	if([self.delegate respondsToSelector:@selector(profilingTarget:didLoadPasteboardContents:)])
	{
		[self.delegate profilingTarget:self didLoadPasteboardContents:_pasteboardContents];
	}
}

- (void)setPasteboardContents:(NSArray<DTXPasteboardItem *> *)pasteboardContents
{
	_pasteboardContents = [pasteboardContents copy];
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeSetPasteboard), @"pasteboardContents": [NSKeyedArchiver archivedDataWithRootObject:pasteboardContents requiringSecureCoding:YES error:NULL]} completionHandler:nil];
}

#pragma mark View Hierarchy

- (void)captureViewHierarchy
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeCaptureViewHierarchy)} completionHandler:nil];
}

- (void)_handleViewHierarchy:(NSDictionary*)viewHierarchy;
{
//	DTXAppSnapshot* appSnapshot = [NSKeyedUnarchiver unarchiveObjectWithData:viewHierarchy[@"appSnapshot"]];
//	NSLog(@"");
}

#pragma mark Remote Profiling

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	if(self.state >= DTXRemoteTargetStateRecording)
	{
		return;
	}
	
	[_uiUpdateTimer invalidate];
	_uiUpdateTimer = nil;
	_state = DTXRemoteTargetStateRecording;
	
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeStartProfilingWithConfiguration), @"configuration": configuration.dictionaryRepresentation} completionHandler:nil];
}

- (void)addTagWithName:(NSString*)name
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeAddTag), @"name": name} completionHandler:nil];
}

- (void)pushSampleGroupWithName:(NSString *)name
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypePushGroup), @"name": name} completionHandler:nil];
}

- (void)popSampleGroup
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypePopGroup)} completionHandler:nil];
}

- (void)stopProfiling
{
	if(_state != DTXRemoteTargetStateRecording)
	{
		return;
	}
	
	_state = DTXRemoteTargetStateStopped;
	
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeStopProfiling)} completionHandler:nil];
}

- (void)_handleProfilerStoryEvent:(NSDictionary*)storyEvent
{
	[self.storyDecoder performBlock:^{
		[self.storyDecoder willDecodeStoryEvent];
		
		BOOL extended = NO;
		SEL cmd = NSSelectorFromString(storyEvent[@"selector"]);
		
		NSMethodSignature* sig = [(id)self.storyDecoder methodSignatureForSelector:cmd];
		if(sig == nil)
		{
			cmd = NSSelectorFromString([NSString stringWithFormat:@"%@entityDescription:", storyEvent[@"selector"]]);
			sig = [(id)self.storyDecoder methodSignatureForSelector:cmd];
			extended = YES;
		}
		
		if(sig != nil)
		{
			NSDictionary* object = storyEvent[@"object"];
			
			NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
			invocation.target = self.storyDecoder;
			invocation.selector = cmd;
			[invocation retainArguments];
			[invocation setArgument:&object atIndex:2];
			
			NSArray* additionalParams = storyEvent[@"additionalParams"];
			__block NSUInteger argIdx = 3;
			[additionalParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				[invocation setArgument:&obj atIndex:argIdx++];
			}];
			
			if(extended)
			{
				NSString* entityName = storyEvent[@"entityName"];
				NSEntityDescription* entityDescription = _managedObjectContext.persistentStoreCoordinator.managedObjectModel.entitiesByName[entityName];
				[invocation setArgument:&entityDescription atIndex:argIdx];
			}
			
			[invocation invoke];
		}
		
		[self.storyDecoder didDecodeStoryEvent];
	}];
}

- (void)_handleRecordingDidStop:(NSDictionary*)storyEvent
{
	
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
