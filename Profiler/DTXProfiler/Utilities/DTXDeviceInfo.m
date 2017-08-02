//
//  DTXDeviceInfo.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 31/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDeviceInfo.h"
#import "DBBuildInfoProvider.h"
#import "DTXReactNativeSampler.h"
@import UIKit;

@implementation DTXDeviceInfo

+ (NSDictionary*)deviceInfoDictionary
{
	DBBuildInfoProvider* buildProvider = [DBBuildInfoProvider new];
	NSProcessInfo* processInfo = [NSProcessInfo processInfo];
	UIDevice* currentDevice = [UIDevice currentDevice];
	
	NSMutableDictionary* deviceDetails = [NSMutableDictionary new];
	deviceDetails[@"appName"] = buildProvider.applicationDisplayName;
	deviceDetails[@"binaryName"] = processInfo.processName;
	deviceDetails[@"deviceName"] = currentDevice.name;
	deviceDetails[@"deviceOS"] = processInfo.operatingSystemVersionString;
	deviceDetails[@"deviceOSType"] = 0;
	deviceDetails[@"devicePhysicalMemory"] = @(processInfo.physicalMemory);
	deviceDetails[@"deviceProcessorCount"] = @(processInfo.activeProcessorCount);
	deviceDetails[@"deviceType"] = currentDevice.model;
	deviceDetails[@"processIdentifier"] = @(processInfo.processIdentifier);
	deviceDetails[@"hasReactNative"] = @([DTXReactNativeSampler reactNativeInstalled]);
	
	return deviceDetails;
}

@end
