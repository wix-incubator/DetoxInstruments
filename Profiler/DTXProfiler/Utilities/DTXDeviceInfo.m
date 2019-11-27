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

+ (NSDictionary*)_uname
{
	struct utsname systemInfo;
	uname(&systemInfo);
	
	return @{@"sysname": [NSString stringWithCString:systemInfo.sysname encoding:NSUTF8StringEncoding],
			 @"nodename": [NSString stringWithCString:systemInfo.nodename encoding:NSUTF8StringEncoding],
			 @"release": [NSString stringWithCString:systemInfo.release encoding:NSUTF8StringEncoding],
			 @"version": [NSString stringWithCString:systemInfo.version encoding:NSUTF8StringEncoding],
			 @"machine": [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding],
			 };
}

+ (NSString *)_bundleName
{
	return [NSBundle.mainBundle objectForInfoDictionaryKey:NS(kCFBundleNameKey)];
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
	static NSMutableDictionary* deviceDetails;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		deviceDetails = [NSMutableDictionary new];
		
		NSDictionary* uname = self._uname;
		
		NSProcessInfo* processInfo = [NSProcessInfo processInfo];
		UIDevice* currentDevice = [UIDevice currentDevice];
		
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
#if ! TARGET_OS_MACCATALYST
		deviceDetails[@"deviceOSType"] = @0;
#else
		deviceDetails[@"deviceOSType"] = @1;
#endif
		deviceDetails[@"devicePhysicalMemory"] = @(processInfo.physicalMemory);
		deviceDetails[@"deviceProcessorCount"] = @(processInfo.activeProcessorCount);
#if ! TARGET_OS_MACCATALYST
		deviceDetails[@"deviceType"] = currentDevice.model;
#else
		deviceDetails[@"deviceType"] = @"macOS";
#endif
		deviceDetails[@"deviceMarketingName"] = MGCopyAnswer(@"marketing-name");
		deviceDetails[@"deviceResolution"] = NSStringFromCGSize(UIScreen.mainScreen.currentMode.size);
		deviceDetails[@"processIdentifier"] = @(processInfo.processIdentifier);
		deviceDetails[@"hasReactNative"] = @([DTXReactNativeSampler isReactNativeInstalled]);
		
		NSString* version = [NSString stringWithFormat:@"%@.%@", [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleVersion"]];
		deviceDetails[@"profilerVersion"] = version;
		
#if ! TARGET_OS_SIMULATOR
		deviceDetails[@"deviceColor"] = MGCopyAnswer(@"DeviceColor");
		deviceDetails[@"deviceEnclosureColor"] = MGCopyAnswer(@"DeviceEnclosureColor");
		deviceDetails[@"machineName"] = uname[@"machine"];
#else
		deviceDetails[@"deviceColor"] = @"1";
		deviceDetails[@"deviceEnclosureColor"] = @"1";
		NSString* deviceTypeSim = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
		deviceDetails[@"machineName"] = deviceTypeSim;
#endif
		deviceDetails[@"kernelName"] = uname[@"sysname"];
		deviceDetails[@"kernelVersion"] = uname[@"release"];
	});
	
	return deviceDetails;
}

@end
