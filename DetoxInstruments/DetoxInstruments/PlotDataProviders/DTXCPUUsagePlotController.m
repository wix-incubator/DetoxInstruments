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

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"CPUActivity"];
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
	return @[[NSColor colorWithRed:23.0/255.0 green:173.0/255.0 blue:255.0/255.0 alpha:1.0]];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_percentFormatter];
}

- (id)transformedValueForFormatter:(id)value
{
	return @(MAX([value doubleValue], 0.0));
}

- (CPTPlotRange*)finesedPlotRangeForPlotRange:(CPTPlotRange*)_yRange;
{
	NSEdgeInsets insets = self.rangeInsets;
	
	CPTMutablePlotRange* yRange = [_yRange mutableCopy];
	
	CGFloat initial = yRange.location.doubleValue;
	yRange.location = @(-insets.bottom);
	yRange.length = @((initial + MAX(yRange.length.doubleValue, 1.0) + insets.top + insets.bottom) * self.yRangeMultiplier);
	
	return yRange;
}

@end
