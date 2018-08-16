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

- (CPTPlotRange*)finesedPlotYRangeForPlotYRange:(CPTPlotRange*)_yRange;
{
	NSEdgeInsets insets = self.rangeInsets;
	
	CPTMutablePlotRange* yRange = [_yRange mutableCopy];
	
	//Leo: Not sure why this was set to what it was set. 0.0 works fine.
	CGFloat initial = 0.0;//yRange.length.doubleValue;
	yRange.location = @(-insets.bottom);
	yRange.length = @((initial + MAX(yRange.length.doubleValue, 1.0) + insets.top + insets.bottom) * self.yRangeMultiplier);
	
	return yRange;
}

@end
