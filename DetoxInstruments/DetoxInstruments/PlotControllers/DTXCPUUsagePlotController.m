//
//  DTXCPUUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCPUUsagePlotController.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXCPUDataProvider.h"

@implementation DTXCPUUsagePlotController

+ (Class)UIDataProviderClass
{
	return [DTXCPUDataProvider class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"CPU Usage", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The CPU Usage instrument captures information about the profiled app's load on the CPU.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"CPUUsage"];
}

- (NSString *)helpTopicName
{
	return @"CPUUsage";
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"cpuUsage"];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"CPU Usage", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.cpuUsagePlotControllerColor];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_percentFormatter];
}

- (id)transformedValueForFormatter:(id)value
{
	return @(MAX([value doubleValue], 0.0));
}

- (CGFloat)minimumValueForPlotHeight
{
	return 1.0;
}

@end
