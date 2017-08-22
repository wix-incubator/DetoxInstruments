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
@import Darwin;

@implementation DTXDeviceInfo

+ (NSString*)_machineName
{
	struct utsname systemInfo;
	
	uname(&systemInfo);
	
	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSDictionary*)deviceInfoDictionary
{
	DBBuildInfoProvider* buildProvider = [DBBuildInfoProvider new];
	NSProcessInfo* processInfo = [NSProcessInfo processInfo];
	UIDevice* currentDevice = [UIDevice currentDevice];
	
	NSMutableDictionary* deviceDetails = [NSMutableDictionary new];
	deviceDetails[@"appName"] = buildProvider.applicationDisplayName;
	deviceDetails[@"binaryName"] = processInfo.processName;
#if ! TARGET_OS_SIMULATOR
	deviceDetails[@"deviceName"] = currentDevice.name;
#else
	NSString* deviceTypeSim = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
	
	deviceDetails[@"deviceName"] = [NSString stringWithFormat:NSLocalizedString(@"%@ Simulator (%@)", @""), deviceTypeSim, currentDevice.name];
#endif
	deviceDetails[@"deviceOS"] = processInfo.operatingSystemVersionString;
	deviceDetails[@"deviceOSType"] = 0;
	deviceDetails[@"devicePhysicalMemory"] = @(processInfo.physicalMemory);
	deviceDetails[@"deviceProcessorCount"] = @(processInfo.activeProcessorCount);
	deviceDetails[@"deviceType"] = currentDevice.model;
	deviceDetails[@"processIdentifier"] = @(processInfo.processIdentifier);
	deviceDetails[@"hasReactNative"] = @([DTXReactNativeSampler reactNativeInstalled]);
	
#if ! TARGET_OS_SIMULATOR
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	SEL selector = NSSelectorFromString(@"deviceInfoForKey:");
	
	if (![currentDevice respondsToSelector:selector])
	{
		selector = NSSelectorFromString(@"_deviceInfoForKey:");
	}
	
	if ([currentDevice respondsToSelector:selector])
	{
		deviceDetails[@"deviceColor"] = [currentDevice performSelector:selector withObject:@"DeviceColor"];
		deviceDetails[@"deviceEnclosureColor"] = [currentDevice performSelector:selector withObject:@"DeviceEnclosureColor"];
	}
#pragma clang diagnostic pop
	
	deviceDetails[@"machineName"] = self._machineName;
#else
	deviceDetails[@"deviceColor"] = @"1";
	deviceDetails[@"deviceEnclosureColor"] = @"1";
	deviceDetails[@"machineName"] = deviceTypeSim;
#endif
	
	return deviceDetails;
}

@end
