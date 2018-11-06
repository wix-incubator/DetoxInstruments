//
//  DTXDeviceInfo.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 31/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDeviceInfo.h"
#import "DTXReactNativeSampler.h"
@import UIKit;
@import Darwin;

static NSString* __version =
#include "version.h"
;

@implementation DTXDeviceInfo

+ (NSString*)_machineName
{
	struct utsname systemInfo;
	
	uname(&systemInfo);
	
	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)_bundleName
{
	return [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
}

+ (NSString *)_applicationDisplayName
{
	NSString* displayName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	return displayName ?: [self _bundleName];
}

+ (NSString *)_buildVersion
{
	return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)_buildNumber
{
	return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (NSString *)_buildInfoString
{
	NSString *buildInfoStringFormat = @"%@, v. %@ (%@)";
	return [NSString stringWithFormat:buildInfoStringFormat, [self _applicationDisplayName], [self _buildVersion], [self _buildNumber]];
}

+ (NSString*)_bundleIdentifier
{
	return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

+ (NSDictionary*)deviceInfo
{
	NSProcessInfo* processInfo = [NSProcessInfo processInfo];
	UIDevice* currentDevice = [UIDevice currentDevice];
	
	NSMutableDictionary* deviceDetails = [NSMutableDictionary new];
	deviceDetails[@"appName"] = self._applicationDisplayName;
	deviceDetails[@"binaryName"] = processInfo.processName;
#if ! TARGET_OS_SIMULATOR
	deviceDetails[@"deviceName"] = currentDevice.name;
#else
	NSString* deviceTypeSim = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
	
	deviceDetails[@"deviceName"] = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ Simulator)", @""), currentDevice.name, deviceTypeSim];
#endif
	deviceDetails[@"deviceOS"] = processInfo.operatingSystemVersionString;
	deviceDetails[@"deviceOSType"] = 0;
	deviceDetails[@"devicePhysicalMemory"] = @(processInfo.physicalMemory);
	deviceDetails[@"deviceProcessorCount"] = @(processInfo.activeProcessorCount);
	deviceDetails[@"deviceType"] = currentDevice.model;
	deviceDetails[@"processIdentifier"] = @(processInfo.processIdentifier);
	deviceDetails[@"hasReactNative"] = @([DTXReactNativeSampler reactNativeInstalled]);
	deviceDetails[@"profilerVersion"] = __version;
	
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
