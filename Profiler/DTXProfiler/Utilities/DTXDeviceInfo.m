//
//  DTXDeviceInfo.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 31/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXDeviceInfo.h"
#import "DTXReactNativeSampler.h"
@import UIKit;
@import Darwin;

@implementation DTXDeviceInfo

+ (NSString*)_machineName
{
	struct utsname systemInfo;
	
	uname(&systemInfo);
	
	return [NSString stringWithCString:systemInfo
#if ! TARGET_OS_SIMULATOR
			.machine
#else
			.nodename
#endif
							  encoding:NSUTF8StringEncoding];
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

extern id MGCopyAnswer(NSString *inKey);

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
	if(processInfo.operatingSystemVersion.majorVersion < 12)
	{
		deviceDetails[@"deviceName"] = [NSString stringWithFormat:NSLocalizedString(@"Simulator (%@)", @""), MGCopyAnswer(@"ComputerName")];
	}
	else
	{
		deviceDetails[@"deviceName"] = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@)", @""), currentDevice.name, MGCopyAnswer(@"ComputerName")];
	}
#endif
	deviceDetails[@"deviceOS"] = processInfo.operatingSystemVersionString;
	deviceDetails[@"deviceOSType"] = @0;
	deviceDetails[@"devicePhysicalMemory"] = @(processInfo.physicalMemory);
	deviceDetails[@"deviceProcessorCount"] = @(processInfo.activeProcessorCount);
	deviceDetails[@"deviceType"] = currentDevice.model;
	deviceDetails[@"deviceMarketingName"] = MGCopyAnswer(@"marketing-name");
	deviceDetails[@"deviceResolution"] = NSStringFromCGSize(UIScreen.mainScreen.currentMode.size);
	deviceDetails[@"processIdentifier"] = @(processInfo.processIdentifier);
	deviceDetails[@"hasReactNative"] = @([DTXReactNativeSampler reactNativeInstalled]);
	
	NSString* version = [NSString stringWithFormat:@"%@.%@", [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	deviceDetails[@"profilerVersion"] = version;
	
#if ! TARGET_OS_SIMULATOR
	deviceDetails[@"deviceColor"] = MGCopyAnswer(@"DeviceColor");
	deviceDetails[@"deviceEnclosureColor"] = MGCopyAnswer(@"DeviceEnclosureColor");
	deviceDetails[@"machineName"] = self._machineName;
#else
	deviceDetails[@"deviceColor"] = @"1";
	deviceDetails[@"deviceEnclosureColor"] = @"1";
	NSString* deviceTypeSim = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
	deviceDetails[@"machineName"] = deviceTypeSim;
#endif
	
	return deviceDetails;
}

@end
