//
//  PreferenceKeys.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/13/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"

NSString* const DTXPreferencesAppearanceKey = @"DTXPreferencesAppearanceKey";
NSString* const DTXPlotSettingsCPUDisplayMTOverlay = @"DTXPlotSettingsCPUDisplayMTOverlay";
NSString* const DTXPlotSettingsCPUThreadColorize = @"DTXPlotSettingsCPUThreadColorize";
NSString* const DTXPlotSettingsIntervalFadeOut = @"DTXPlotSettingsIntervalFadeOut";
NSString* const DTXPlotSettingsDisplayHoverTextAnnotations = @"DTXPlotSettingsDisplayHoverTextAnnotations";
NSString* const DTXPlotSettingsDisplaySelectionTextAnnotations = @"DTXPlotSettingsDisplaySelectionTextAnnotations";
NSString* const DTXPlotSettingsDisplayLabels = @"DTXPlotSettingsDisplayLabels";
NSString* const DTXPreferencesLaunchProfilingDuration = @"DTXPreferencesLaunchProfilingDuration";

__attribute__((constructor))
static void initPreferences(void)
{
	[NSUserDefaults.standardUserDefaults registerDefaults:@{@"DTXSelectedProfilingConfiguration_timeLimit": @2}];
	[NSUserDefaults.standardUserDefaults registerDefaults:@{@"DTXSelectedProfilingConfiguration_timeLimitType": @1}];
	
	[NSUserDefaults.standardUserDefaults registerDefaults:@{@"DTXSelectedProfilingConfiguration_recordPerformance": @YES}];
	[NSUserDefaults.standardUserDefaults registerDefaults:@{@"DTXSelectedProfilingConfiguration_recordEvents": @YES}];
	
	if([NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration_recordInternalReactNativeEvents"] != nil)
	{
		[NSUserDefaults.standardUserDefaults setBool:[NSUserDefaults.standardUserDefaults boolForKey:@"DTXSelectedProfilingConfiguration_recordInternalReactNativeEvents"] forKey:@"DTXSelectedProfilingConfiguration_recordInternalReactNativeActivity"];
		[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DTXSelectedProfilingConfiguration_recordInternalReactNativeEvents"];
	}
	
	if([NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration_recordReactNativeTimersAsEvents"] != nil)
	{
		[NSUserDefaults.standardUserDefaults setBool:[NSUserDefaults.standardUserDefaults boolForKey:@"DTXSelectedProfilingConfiguration_recordReactNativeTimersAsEvents"] forKey:@"DTXSelectedProfilingConfiguration_recordReactNativeTimersAsActivity"];
		[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DTXSelectedProfilingConfiguration_recordReactNativeTimersAsEvents"];
	}
	
	if([NSUserDefaults.standardUserDefaults boolForKey:@"DTXSelectedProfilingConfiguration_recordInternalReactNativeEvents"] == YES)
	{
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DTXSelectedProfilingConfiguration_recordInternalReactNativeActivity"];
		[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DTXSelectedProfilingConfiguration_recordInternalReactNativeEvents"];
	}
	
	[NSUserDefaults.standardUserDefaults registerDefaults:@{DTXPlotSettingsCPUDisplayMTOverlay: @YES, DTXPlotSettingsCPUThreadColorize: @NO, DTXPreferencesAppearanceKey: @0, DTXPlotSettingsIntervalFadeOut:@YES, DTXPlotSettingsDisplayHoverTextAnnotations: @YES, DTXPlotSettingsDisplaySelectionTextAnnotations: @YES, DTXPlotSettingsDisplayLabels: @YES, DTXPreferencesLaunchProfilingDuration: @15.0}];
	
	[NSUserDefaults.standardUserDefaults setObject:[NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration_ignoredCategoriesArray"] forKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"];
	[NSUserDefaults.standardUserDefaults setObject:nil forKey:@"DTXSelectedProfilingConfiguration_ignoredCategoriesArray"];
	
	[DTXProfilingConfiguration registerRemoteProfilingDefaults];
}
