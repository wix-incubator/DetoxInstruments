//
//  DTXRecordingTargetPickerViewController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXRecordingTargetPickerViewController+DocumentationGeneration.h"

@interface __FAKE_DTXRemoteProfilingTarget : NSObject

@property (nonatomic, assign) NSUInteger deviceOSType;
@property (nonatomic, copy) NSString* appName;
@property (nonatomic, copy) NSString* deviceName;
@property (nonatomic, copy) NSString* deviceOS;
@property (nonatomic, copy) NSImage* deviceSnapshot;
@property (nonatomic, copy) NSDictionary* deviceInfo;

@property (nonatomic, assign) DTXRemoteProfilingTargetState state;

@end

@implementation __FAKE_DTXRemoteProfilingTarget @end

@interface DTXRecordingTargetPickerViewController ()

- (void)_addTarget:(DTXRemoteProfilingTarget*)target forService:(NSNetService*)service;

@end

@implementation DTXRecordingTargetPickerViewController (DocumentationGeneration)

- (void)_addFakeTarget
{
	/*
	 (lldb) po target.appName
	 StressTestApp
	 
	 (lldb) po target.deviceName
	 iPhone Simulator (Leo Natan's Wix MPB)
	 
	 (lldb) po target.deviceOS
	 Version 11.4 (Build 15F5037c)
	 
	 (lldb) po target.deviceInfo
	 {
	 appName = StressTestApp;
	 binaryName = StressTestApp;
	 cmdType = 1;
	 deviceColor = 1;
	 deviceEnclosureColor = 1;
	 deviceName = "iPhone Simulator (Leo Natan's Wix MPB)";
	 deviceOS = "Version 11.4 (Build 15F5037c)";
	 devicePhysicalMemory = 17179869184;
	 deviceProcessorCount = 8;
	 deviceType = iPhone;
	 hasReactNative = 0;
	 machineName = iPhone;
	 processIdentifier = 50554;
	 profilerVersion = "0.9.1";
	 }
	 */
	
	__FAKE_DTXRemoteProfilingTarget* fakeTarget = [__FAKE_DTXRemoteProfilingTarget new];
	fakeTarget.deviceOS = 0;
	fakeTarget.appName = @"Example App";
	fakeTarget.deviceName = @"iPhone X";
	fakeTarget.deviceOS = @"Version 11.4 (Build 15F5037c)";
	fakeTarget.deviceInfo = @{@"profilerVersion": @"0.9.1"};
	fakeTarget.state = DTXRemoteProfilingTargetStateDeviceInfoLoaded;
	
	[self _addTarget:(id)fakeTarget forService:(id)[NSObject new]];
}

@end
