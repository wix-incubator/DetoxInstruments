//
//  DTXRemoteProfilingConnectionManager.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/25/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRemoteProfilingConnectionManager.h"
#import "DTXSocketConnection.h"
#import "DTXRemoteProfiler.h"
#import "DTXProfilingBasics.h"
#import "DTXDeviceInfo.h"
#import "DTXFileSystemItem.h"
#import "AutoCoding.h"
#import "DTXZipper.h"
#import "DTXUIPasteboardParser.h"
#import "DTXViewHierarchySnapshotter.h"
#import "DTXWindowsSnapshotter.h"

DTX_CREATE_LOG(RemoteProfilingConnectionManager);

@interface DTXRemoteProfilingConnectionManager () <DTXSocketConnectionDelegate, DTXRemoteProfilerDelegate>

@end

@implementation DTXRemoteProfilingConnectionManager
{
	BOOL _aborted;
	
	DTXSocketConnection* _connection;
	DTXRemoteProfiler* _remoteProfiler;
}

+ (NSData*)_dataForNetworkCommand:(NSDictionary*)cmd
{
	return [NSPropertyListSerialization dataWithPropertyList:cmd format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
}

+ (NSDictionary*)_responseFromNetworkData:(NSData*)data
{
	return [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
}

- (instancetype)initWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream
{
	self = [super init];
	
	if(self)
	{
		dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
		_connection = [[DTXSocketConnection alloc] initWithInputStream:inputStream outputStream:outputStream queue:dtx_dispatch_queue_create_autoreleasing("com.wix.DTXRemoteProfiler-Networking", qosAttribute)];
		_connection.delegate = self;
		
		[_connection open];
		
		[self _nextCommand];
	}
	
	return self;
}

- (void)_writeCommand:(NSDictionary*)cmd completionHandler:(void (^)(void))completionHandler
{
	completionHandler = completionHandler ?: ^ () {};
	
	[_connection writeData:[DTXRemoteProfilingConnectionManager _dataForNetworkCommand:cmd] completionHandler:^(NSError * _Nullable error) {
		if(error) {
			[self.delegate remoteProfilingConnectionManager:self didFinishWithError:error];
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
			[self.delegate remoteProfilingConnectionManager:self didFinishWithError:error];
			return;
		}
		
		NSDictionary* dict = [DTXRemoteProfilingConnectionManager _responseFromNetworkData:data];
		
		completionHandler(dict);
	}];
}

- (BOOL)isProfiling
{
	return _remoteProfiler != nil;
}

- (void)abortConnectionAndProfiling
{
	self->_aborted = YES;
	
	[self->_connection closeRead];
	[self->_connection closeWrite];
	
	self->_connection = nil;
	
	[_remoteProfiler stopProfilingWithCompletionHandler:nil];
	_remoteProfiler = nil;
}

#pragma mark Socket Commands

- (void)_nextCommand
{
	[self _readCommandWithCompletionHandler:^(NSDictionary *cmd) {
		DTXRemoteProfilingCommandType cmdType = [cmd[@"cmdType"] unsignedIntegerValue];
		switch (cmdType) {
			case DTXRemoteProfilingCommandTypePing:
			{
			}	break;
			case DTXRemoteProfilingCommandTypeGetDeviceInfo:
			{
				[self _sendDeviceInfo];
			} 	break;
			case DTXRemoteProfilingCommandTypeLoadScreenSnapshot:
			{
				[self _sendScreenSnapshot];
			} 	break;
			case DTXRemoteProfilingCommandTypeStartProfilingWithConfiguration:
			{
				NSDictionary* configDict = cmd[@"configuration"];
				DTXProfilingConfiguration* config = configDict == nil ? [DTXProfilingConfiguration defaultProfilingConfiguration] : [[DTXProfilingConfiguration alloc] initWithCoder:(id)configDict];
				self->_remoteProfiler = [[DTXRemoteProfiler alloc] initWithOpenedSocketConnection:self->_connection remoteProfilerDelegate:self];
				[self->_remoteProfiler startProfilingWithConfiguration:config];
				[self.delegate remoteProfilingConnectionManagerDidStartProfiling:self];
			}	break;
			case DTXRemoteProfilingCommandTypeStartLaunchProfilingWithConfiguration:
			{
				NSDictionary* configDict = cmd[@"configuration"];
				NSString* remoteSession = cmd[@"launchProfilingSession"];
				NSNumber* duration = cmd[@"profilingDuration"];
				[NSUserDefaults.standardUserDefaults setObject:@{@"session": remoteSession, @"config": configDict, @"duration": duration} forKey:@"_dtxprofiler_pendingLaunchProfiling"];
				[NSUserDefaults.standardUserDefaults synchronize];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					UIViewController* targetViewController = nil;
					
					if(@available(iOS 13, *))
					{
						targetViewController = [UIWindowScene valueForKeyPath:@"keyWindowScene.keyWindow.rootViewController"];
					}
					else
					{
						targetViewController = [UIWindow valueForKeyPath:@"keyWindow.rootViewController"];
					}
					
					//Terminate on background.
					[NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
						[UIApplication.sharedApplication valueForKey:@"terminateWithSuccess"];
					}];
					
					//Terminate on user alert.
					UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"App Launch Profiling", @"") message:NSLocalizedString(@"Tap the Terminate button to terminate the app. Launch it again to begin app launch profiling.", @"") preferredStyle:UIAlertControllerStyleAlert];
					[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Terminate", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
						[UIApplication.sharedApplication valueForKey:@"terminateWithSuccess"];
					}]];
					
					[targetViewController presentViewController:alert animated:YES completion:nil];
				});
			}	break;
			case DTXRemoteProfilingCommandTypeAddTag:
			{
				NSString* name = cmd[@"name"];
				[self->_remoteProfiler _addTag:name timestamp:NSDate.date];
			}	break;
CLANG_IGNORE(-Wdeprecated-declarations)
			case DTXRemoteProfilingCommandTypePushGroup:
			case DTXRemoteProfilingCommandTypePopGroup:
				break;
CLANG_POP
			case DTXRemoteProfilingCommandTypeStopProfiling:
			{
				[self->_remoteProfiler stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
					[self _sendRecordingDidStop];
				}];
				self->_remoteProfiler = nil;
			}	break;
			case DTXRemoteProfilingCommandTypeProfilingStoryEvent:
			{
				NSAssert(NO, @"Should not be here.");
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
			case DTXRemoteProfilingCommandTypePutContainerItem:
			{
				NSURL* URL = [NSURL fileURLWithPath:cmd[@"URL"]];
				NSData* data = cmd[@"contents"];
				bool wasZipped = [cmd[@"wasZipped"] boolValue];
				[self _putContainerItemWithURL:URL data:data wasZipped:wasZipped];
			}	break;
				
			case DTXRemoteProfilingCommandTypeGetUserDefaults:
			{
				[self _sendUserDefaults];
				
			}	break;
			case DTXRemoteProfilingCommandTypeChangeUserDefaultsItem:
			{
				NSString* key = cmd[@"key"];
				NSString* previousKey = cmd[@"previousKey"];
				id value = cmd[@"value"];
				DTXUserDefaultsChangeType type = [cmd[@"type"] unsignedIntegerValue];
				
				[self _changeUserDefaultsItemWithKey:key changeType:type value:value previousKey:previousKey];
			}	break;
			case DTXRemoteProfilingCommandTypeGetCookies:
			{
				[self _sendCookies];
			}	break;
			case DTXRemoteProfilingCommandTypeSetCookies:
			{
				[self _setCookies:cmd[@"cookies"]];
			}	break;
				
			case DTXRemoteProfilingCommandTypeGetPasteboard:
			{
				[self _sendPasteboard];
			}	break;
			case DTXRemoteProfilingCommandTypeSetPasteboard:
			{
				NSArray<DTXPasteboardItem*>* pasteboard = [NSKeyedUnarchiver dtx_unarchiveObjectWithData:cmd[@"pasteboardContents"] requiringSecureCoding:NO error:NULL];
				[self _setPasteboard:pasteboard];
				
			}	break;
			case DTXRemoteProfilingCommandTypeCaptureViewHierarchy:
			{
				[self _sendViewHierarchy];
			}	break;
			default:
				break;
		}
		
		[self _nextCommand];
	}];
}

#pragma mark Device Info

- (void)_sendDeviceInfo
{
	NSMutableDictionary* cmd = [[DTXDeviceInfo deviceInfo] mutableCopy];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeGetDeviceInfo);
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_sendScreenSnapshot
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSData* png = [DTXWindowsSnapshotter snapshotDataForApp];
		
		NSMutableDictionary* cmd = [NSMutableDictionary new];
		cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeLoadScreenSnapshot);
		cmd[@"screenSnapshot"] = png;
		
		[self _writeCommand:cmd completionHandler:nil];
	});
}

#pragma mark Container Contents

- (void)_sendContainerContents
{
#if ! TARGET_OS_MACCATALYST
	NSURL* baseDataURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@".."] URLByStandardizingPath];
	DTXFileSystemItem* rootItem = [[DTXFileSystemItem alloc] initWithFileURL:baseDataURL];
#else
	DTXFileSystemItem* rootItem = [[DTXFileSystemItem alloc] initWithFileURL:NSBundle.mainBundle.bundleURL];
#endif
	
	NSMutableDictionary* cmd = [NSMutableDictionary new];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeGetContainerContents);
	cmd[@"containerContents"] = [NSKeyedArchiver archivedDataWithRootObject:rootItem requiringSecureCoding:NO error:NULL];
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_deleteContainerItemWithURL:(NSURL*)URL
{
	if(URL != nil)
	{
		[[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
	}
}

- (void)_putContainerItemWithURL:(NSURL*)URL data:(NSData*)data wasZipped:(BOOL)wasZipped
{
	if(wasZipped == NO)
	{
		[data writeToURL:URL atomically:YES];
		return;
	}
	
	NSURL* tempZipURL = DTXTempZipURL();
	[data writeToURL:tempZipURL atomically:YES];
	
	DTXExtractZipToURL(tempZipURL, URL);
	
	[[NSFileManager defaultManager] removeItemAtURL:tempZipURL error:NULL];
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

#pragma mark User Defaults

- (void)_sendUserDefaults
{
	NSMutableDictionary* cmd = [NSMutableDictionary new];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeGetUserDefaults);
	cmd[@"userDefaults"] = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_changeUserDefaultsItemWithKey:(NSString*)key changeType:(DTXUserDefaultsChangeType)changeType value:(id)value previousKey:(NSString*)previousKey
{
	if(previousKey != nil && [previousKey isEqualToString:key] == NO)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:previousKey];
	}
	
	if(changeType == DTXUserDefaultsChangeTypeDelete)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
	}
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Cookies

- (void)_sendCookies
{
	NSMutableDictionary* cmd = [NSMutableDictionary new];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeGetCookies);
	cmd[@"cookies"] = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] valueForKey:@"properties"];
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_setCookies:(NSArray<NSDictionary<NSString*, id>*>*)cookies
{
	//Delete all old cookies
	[[[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies] copy] enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:obj];
	}];
	
	[cookies enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:obj];
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
	}];
}

#pragma mark Pasteboard

- (void)_sendPasteboard
{
	NSMutableDictionary* cmd = [NSMutableDictionary new];
	cmd[@"cmdType"] = @(DTXRemoteProfilingCommandTypeGetPasteboard);
	
	cmd[@"pasteboardContents"] = [NSKeyedArchiver archivedDataWithRootObject:[DTXUIPasteboardParser pasteboardItemsFromGeneralPasteboard] requiringSecureCoding:NO error:NULL];
	
	[self _writeCommand:cmd completionHandler:nil];
}

- (void)_setPasteboard:(NSArray<DTXPasteboardItem*>*)pasteboard
{
	[DTXUIPasteboardParser setGeneralPasteboardItems:pasteboard];
}

#pragma mark View Hierarchy

- (void)_sendViewHierarchy
{
	[DTXViewHierarchySnapshotter captureViewHierarchySnapshotWithCompletionHandler:^(DTXAppSnapshot *snapshot) {
		[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeCaptureViewHierarchy), @"appSnapshot": [NSKeyedArchiver archivedDataWithRootObject:snapshot requiringSecureCoding:NO error:NULL]} completionHandler:nil];
	}];
}

#pragma mark Remote Profiling

- (void)_sendRecordingDidStop
{
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeStopProfiling)} completionHandler:nil];
}

- (void)sendFinishedLaunchProfilingRecordingWithURL:(NSURL*)URL
{
	DTXFileSystemItem* recording = [[DTXFileSystemItem alloc] initWithFileURL:URL];
	NSData* data = recording.zipContents;
	
	[self _writeCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeStartLaunchProfilingWithConfiguration), @"recordingZipData": data} completionHandler:nil];
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
	
	[self.delegate remoteProfilingConnectionManager:self didFinishWithError:error];
}

#pragma mark DTXSocketConnectionDelegate

- (void)readClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	[socketConnection closeWrite];
	
	dtx_log_info(@"Socket connection closed for reading");
	
	_connection = nil;
	
	if(_aborted)
	{
		return;
	}
	
	[self.delegate remoteProfilingConnectionManager:self didFinishWithError:nil];
}

- (void)writeClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	[socketConnection closeRead];
	
	dtx_log_info(@"Socket connection closed for writing");
	
	_connection = nil;
	
	if(_aborted)
	{
		return;
	}
	
	[self.delegate remoteProfilingConnectionManager:self didFinishWithError:nil];
}

@end
