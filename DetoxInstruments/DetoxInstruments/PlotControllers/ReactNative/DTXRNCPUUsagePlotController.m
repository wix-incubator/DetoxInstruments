//
//  DTXRNCPUUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXRNCPUUsagePlotController.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXRNCPUDataProvider.h"
#endif
#import "NSColor+UIAdditions.h"

@implementation DTXRNCPUUsagePlotController

#if ! PROFILER_PREVIEW_EXTENSION
+ (Class)UIDataProviderClass
{
	return [DTXRNCPUDataProvider class];
}
#endif

+ (Class)classForPerformanceSamples
{
	return [DTXReactNativePerformanceSample class];
}

- (NSString *)displayName
{
#if ! PROFILER_PREVIEW_EXTENSION
	return NSLocalizedString(@"JavaScript Thread", @"");
#else
	return NSLocalizedString(@"JS Thread", @"");
#endif
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The JavaScript Thread instrument captures information about the CPU load of the profiled app's JavaScript thread.", @"");
}

- (NSString *)helpTopicName
{
	return @"JavaScriptThread";
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"CPUUsage"];
}

- (NSImage *)secondaryIcon
{
	return [NSImage imageNamed:@"react"];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.cpuUsagePlotControllerColor];
}

@end
