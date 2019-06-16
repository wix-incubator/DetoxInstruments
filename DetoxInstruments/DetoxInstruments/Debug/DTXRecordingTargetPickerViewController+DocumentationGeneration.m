//
//  DTXRecordingTargetPickerViewController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#if DEBUG

#import "DTXRecordingTargetPickerViewController+DocumentationGeneration.h"
#import "DevicePreviewImagesDocumentationGeneration.h"

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface __FAKE_DTXRemoteTarget : NSObject

@property (nonatomic, assign) NSUInteger deviceOSType;
@property (nonatomic, copy) NSString* appName;
@property (nonatomic, copy) NSString* deviceName;
@property (nonatomic, copy) NSString* devicePresentable;
@property (nonatomic, copy) NSImage* screenSnapshot;
@property (nonatomic, copy) NSDictionary* deviceInfo;

@property (nonatomic, strong) DTXFileSystemItem* containerContents;
@property (nonatomic, strong) id userDefaults;
@property (nonatomic, strong) NSArray<NSDictionary<NSString*, id>*>* cookies;
@property (nonatomic, copy) NSArray<DTXPasteboardItem*>* pasteboardContents;

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

- (BOOL)isCompatibleWithInstruments
{
	return YES;
}


@end

@interface DTXRecordingTargetPickerViewController ()

- (void)_addLocalTarget:(DTXRemoteTarget*)target forService:(NSNetService*)service announceToOutlineView:(BOOL)announce;
- (IBAction)_manageProfilingTarget:(NSButton*)sender;

@end

@implementation DTXRecordingTargetPickerViewController (DocumentationGeneration)

static __FAKE_DTXRemoteTarget* fakeTarget;

- (void)_addFakeTarget
{
	fakeTarget = [__FAKE_DTXRemoteTarget new];
	fakeTarget.appName = @"Example App";
	fakeTarget.deviceName = @"Leo Natan's iPhone";
	fakeTarget.devicePresentable = @"iPhone XS Max, iOS 12.1 (Build 16A405)";
	fakeTarget.deviceInfo = @{@"profilerVersion": @"1.4", @"machineName": @"iPhone11,6"};
	fakeTarget.screenSnapshot = __DTXiPhoneXSMaxScreenshot();
	fakeTarget.state = DTXRemoteTargetStateDeviceInfoLoaded;
	
	fakeTarget.delegate = (id)self;
	
	[self _addLocalTarget:(id)fakeTarget forService:(id)[NSObject new] announceToOutlineView:YES];
	
	__FAKE_DTXRemoteTarget* fakeTarget = [__FAKE_DTXRemoteTarget new];
	fakeTarget.appName = @"Another App";
	fakeTarget.deviceName = @"Development iPad Pro";
	fakeTarget.devicePresentable = @"iPad Pro, iOS 12.1 (Build 16A405)";
	fakeTarget.deviceInfo = @{@"profilerVersion": @"200.0", @"machineName": @"iPad5.3", @"deviceEnclosureColor": @2};
	fakeTarget.screenSnapshot = __DTXiPadScreenshot();
	fakeTarget.state = DTXRemoteTargetStateDeviceInfoLoaded;
	
	fakeTarget.delegate = (id)self;
	
	[self _addLocalTarget:(id)fakeTarget forService:(id)[NSObject new] announceToOutlineView:YES];
}

- (DTXProfilingTargetManagementWindowController*)_openManagementWindowController
{
	NSOutlineView* outlineView = [self valueForKey:@"outlineView"];
	[self _manageProfilingTarget:[[outlineView viewAtColumn:0 row:0 makeIfNecessary:NO] valueForKey:@"manageButton"]];
	return [[self valueForKey:@"_targetManagementControllers"] objectForKey:fakeTarget];
}

@end

#endif
