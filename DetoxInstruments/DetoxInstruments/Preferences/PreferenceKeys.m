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

__attribute__((constructor))
static void initPreferences(void)
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXSelectedProfilingConfiguration_timeLimit": @2}];
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXSelectedProfilingConfiguration_timeLimitType": @1}];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXSelectedProfilingConfiguration_recordPerformance": @YES}];
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXSelectedProfilingConfiguration_recordEvents": @YES}];
	
	[NSUserDefaults.standardUserDefaults registerDefaults:@{DTXPlotSettingsCPUDisplayMTOverlay: @YES, DTXPlotSettingsCPUThreadColorize: @NO, DTXPreferencesAppearanceKey: @0, DTXPlotSettingsIntervalFadeOut:@YES, DTXPlotSettingsDisplayHoverTextAnnotations: @YES, DTXPlotSettingsDisplaySelectionTextAnnotations: @YES, DTXPlotSettingsDisplayLabels: @YES}];
	
	[NSUserDefaults.standardUserDefaults setObject:[NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration_ignoredCategoriesArray"] forKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"];
	[NSUserDefaults.standardUserDefaults setObject:nil forKey:@"DTXSelectedProfilingConfiguration_ignoredCategoriesArray"];
	
	[DTXProfilingConfiguration registerRemoteProfilingDefaults];
}
