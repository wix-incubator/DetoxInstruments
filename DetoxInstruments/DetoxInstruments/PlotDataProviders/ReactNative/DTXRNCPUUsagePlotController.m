//
//  DTXRNCPUUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRNCPUUsagePlotController.h"
#import "DTXRNCPUDataProvider.h"

@implementation DTXRNCPUUsagePlotController

+ (Class)UIDataProviderClass
{
	return [DTXRNCPUDataProvider class];
}

- (Class)classForPerformanceSamples
{
	return [DTXReactNativePeroformanceSample class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"JavaScript Thread", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The JavaScript Thread instrument captures information about the CPU load of the profiled app's JavaScript thread.", @"");
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
	return @[[NSColor colorWithRed:23.0/255.0 green:173.0/255.0 blue:255.0/255.0 alpha:1.0]];
}

@end
