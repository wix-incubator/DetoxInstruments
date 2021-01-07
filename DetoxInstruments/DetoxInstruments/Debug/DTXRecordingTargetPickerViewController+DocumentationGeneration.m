//
//  DTXRecordingTargetPickerViewController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#if DEBUG

#import "DTXRecordingTargetPickerViewController+DocumentationGeneration.h"
#import "DevicePreviewImagesDocumentationGeneration.h"
#import <stdlib.h>

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface __FAKE_DTXRemoteTarget : NSObject

@property (nonatomic, assign) NSUInteger deviceOSType;
@property (nonatomic, copy) NSString* appName;
@property (nonatomic, copy) NSString* deviceName;
@property (nonatomic, copy) NSString* devicePresentable;
@property (nonatomic, copy) NSImage* screenSnapshot;
@property (nonatomic, copy) NSDictionary* deviceInfo;
@property (nonatomic) BOOL hasReactNative;

@property (nonatomic, strong) DTXFileSystemItem* containerContents;
@property (nonatomic, strong) id userDefaults;
@property (nonatomic, strong) NSArray<NSDictionary<NSString*, id>*>* cookies;
@property (nonatomic, copy) NSArray<DTXPasteboardItem*>* pasteboardContents;
@property (nonatomic, strong) id asyncStorage;

@property (nonatomic, weak) id<DTXRemoteTargetDelegate> delegate;

@property (nonatomic, assign) DTXRemoteTargetState state;

@end

@implementation __FAKE_DTXRemoteTarget

- (void)loadContainerContents
{
	self.containerContents = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/ContainerContents.dat"]];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate profilingTargetdidLoadContainerContents:(id)self];
	});
}

- (void)loadPasteboardContents
{
	self.pasteboardContents = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/Pasteboard.dat"]];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate profilingTarget:(id)self didLoadPasteboardContents:self.pasteboardContents];
	});
}

- (void)loadCookies
{
	self.cookies = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/Cookies.dat"]];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate profilingTarget:(id)self didLoadCookies:self.cookies];
	});
}

- (void)loadUserDefaults
{
	self.userDefaults = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/UserDefaults.dat"]];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate profilingTarget:(id)self didLoadUserDefaults:self.userDefaults];
	});
}

- (void)loadAsyncStorage;
{
	self.asyncStorage = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"] stringByAppendingPathComponent:@"../Documentation/Example Recording/Example Management Data/AsyncStorage.dat"]];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate profilingTarget:(id)self didLoadAsyncStorage:self.asyncStorage];
	});
}

- (void)startStreamingLogsWithHandler:(void(^)(BOOL isFromAppProcess, NSString* processName, BOOL isFromApple, NSDate* timestamp, DTXProfilerLogLevel level, NSString* __nullable subsystem, NSString* __nullable category, NSString* message))handler
{
	NSArray<NSDictionary<NSString*, NSString*>*>* exampleLogOutputs = @[
		@{
			@"message": @"[CLIoHidInterface] Refreshing service refs",
			@"subsystem": @"HID",
			@"category": @"CLI"
		},
		@{
			@"message": @"Fetching effective device orientation with temporary manager: faceUp (5)",
			@"subsystem": @"com.apple.uikit",
			@"category": @"General"
		},
		@{
			@"message": @"Updating device orientation from CoreMotion to: faceUp (5)",
			@"subsystem": @"",
			@"category": @""
		},
		@{
			@"message": @"-[BrightnessSystemInternal copyPropertyForKey:client:]: client=4304426368 key=<private>",
			@"subsystem": @"",
			@"category": @""
		},
		@{
			@"message": @"@ClxSimulated, Fix, 1, ll, 37.7858340, -122.4064170, acc, 5.00, course, -1.0, time, 625309318.0",
			@"subsystem": @"com.apple.locationd.Position",
			@"category": @"CLX"
		},
		@{
			@"message": @"_xpc_activity_dispatch: beginning dispatch, activity name com.apple.fontservicesd.subscription-support, seqno 0",
			@"subsystem": @"com.apple.xpc.activity",
			@"category": @"Client"
		},
		@{
			@"message": @"Running XPC Activity (PID 1100): com.apple.fontservicesd.subscription-support (0x7fd002f083a0)",
			@"subsystem": @"com.apple.xpc.activity",
			@"category": @"Activities"
		},
	];
	
	NSArray<NSNumber*>* exampleLevels = @[
		@(DTXProfilerLogLevelDebug),
		@(DTXProfilerLogLevelInfo),
		@(DTXProfilerLogLevelNotice),
		@(DTXProfilerLogLevelError),
		@(DTXProfilerLogLevelFault),
	];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		for(NSUInteger idx = 0; idx < 20; idx++)
		{
			NSUInteger level = idx == 2 ? DTXProfilerLogLevelError : exampleLevels[arc4random_uniform((uint32_t)exampleLevels.count)].unsignedIntValue;
			
			NSDictionary* logEntry = exampleLogOutputs[arc4random_uniform((uint32_t)exampleLogOutputs.count)];
			
			handler(YES, @"ExampleApp", NO, [NSDate dateWithTimeIntervalSinceNow:idx], level, logEntry[@"subsystem"], logEntry[@"category"], logEntry[@"message"]);
		}
	});
}

- (void)stopStreamingLogs
{
	
}

- (BOOL)isCompatibleWithInstruments
{
	return YES;
}


@end

@interface DTXRecordingTargetPickerViewController ()

- (void)_addLocalTarget:(DTXRemoteTarget*)target forService:(NSNetService*)service announceToOutlineView:(BOOL)announce;
- (IBAction)_streamLogOfProfilingTarget:(NSButton*)sender;
- (IBAction)_manageProfilingTarget:(NSButton*)sender;

@end

@implementation DTXRecordingTargetPickerViewController (DocumentationGeneration)

static __FAKE_DTXRemoteTarget* fakeTarget;

- (void)_addFakeTarget
{
	fakeTarget = [__FAKE_DTXRemoteTarget new];
	fakeTarget.appName = @"Example App";
	fakeTarget.deviceName = @"Leo Natan's iPhone";
	fakeTarget.devicePresentable = @"iPhone 12 Pro Max, iOS 14.2 (Build 18B5072e)";
	fakeTarget.deviceInfo = @{@"profilerVersion": @"1.14", @"machineName": @"iPhone13,4"};
	fakeTarget.hasReactNative = YES;
	fakeTarget.screenSnapshot = __DTXiPhoneXSMaxScreenshot();
	fakeTarget.state = DTXRemoteTargetStateDeviceInfoLoaded;
	
	fakeTarget.delegate = (id)self;
	
	[self _addLocalTarget:(id)fakeTarget forService:(id)[NSObject new] announceToOutlineView:YES];
	
	__FAKE_DTXRemoteTarget* fakeTarget = [__FAKE_DTXRemoteTarget new];
	fakeTarget.appName = @"Another App";
	fakeTarget.deviceName = @"Development iPad Pro";
	fakeTarget.devicePresentable = @"iPad Pro, iOS 14.2 (Build 18B5072e)";
	fakeTarget.deviceInfo = @{@"profilerVersion": @"200.0", @"machineName": @"iPad5.3", @"deviceEnclosureColor": @2};
	fakeTarget.screenSnapshot = __DTXiPadScreenshot();
	fakeTarget.state = DTXRemoteTargetStateDeviceInfoLoaded;
	
	fakeTarget.delegate = (id)self;
	
	[self _addLocalTarget:(id)fakeTarget forService:(id)[NSObject new] announceToOutlineView:YES];
}

- (DTXLiveLogWindowController*)_openLiveConsoleWindowController
{
	NSOutlineView* outlineView = [self valueForKey:@"outlineView"];
	[self _streamLogOfProfilingTarget:[[outlineView viewAtColumn:0 row:0 makeIfNecessary:NO] valueForKey:@"consoleButton"]];
	return [[self valueForKey:@"_targetLogControllers"] objectForKey:fakeTarget];
}

- (DTXProfilingTargetManagementWindowController*)_openManagementWindowController
{
	NSOutlineView* outlineView = [self valueForKey:@"outlineView"];
	[self _manageProfilingTarget:[[outlineView viewAtColumn:0 row:0 makeIfNecessary:NO] valueForKey:@"manageButton"]];
	return [[self valueForKey:@"_targetManagementControllers"] objectForKey:fakeTarget];
}

@end

#endif
