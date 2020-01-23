//
//  DTXRNBridgeCountersPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 31/07/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNBridgeCountersPlotController.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXRNBridgeCallsDataProvider.h"
#endif
#import "NSFormatter+PlotFormatters.h"

@implementation DTXRNBridgeCountersPlotController

#if ! PROFILER_PREVIEW_EXTENSION
+ (Class)UIDataProviderClass
{
	return [DTXRNBridgeCallsDataProvider class];
}
#endif

+ (Class)classForPerformanceSamples
{
	return [DTXReactNativePerformanceSample class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Bridge Counters", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Bridge Counters instrument captures information about React Native bridge calls made by the profiled app.", @"");
}

- (NSString *)helpTopicName
{
	return @"BridgeCounters";
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"RNBridgeCounters"];
}

- (NSImage *)secondaryIcon
{
	return [NSImage imageNamed:@"react"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"bridgeNToJSCallCountDelta", @"bridgeJSToNCallCountDelta"];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor.systemPurpleColor colorWithAlphaComponent:1.0], [NSColor.systemOrangeColor colorWithAlphaComponent:1.0]];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"Native to JavaScript", @""), NSLocalizedString(@"JavaScript to Native", @"")];
}

- (NSArray<NSString*>*)legendTitles
{
	return @[NSLocalizedString(@"N → JS", @""), NSLocalizedString(@"JS → N", @"")];
}

- (BOOL)isStepped
{
	return YES;
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_stringFormatter];
}

- (BOOL)includeSeparatorsInStackView
{
	return self.isForTouchBar;
}

@end
