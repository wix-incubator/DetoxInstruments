//
//  DTXRNCPUDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRNCPUDataProvider.h"
#import "DTXRNCPUInspectorDataProvider.h"
#import "DTXRNCPUUsageDataExporter.h"

@implementation DTXRNCPUDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXRNCPUInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXRNCPUUsageDataExporter.class;
}

- (Class)sampleClass
{
	return DTXReactNativePeroformanceSample.class;
}

- (NSString*)titleOfCPUHeader
{
	return NSLocalizedString(@"JavaScript Thread CPU Usage", @"");
}

- (BOOL)showsHeaviestThreadColumn
{
	return NO;
}

- (NSColor*)backgroundRowColorForItem:(id)item
{
	DTXReactNativePeroformanceSample* sample = item;
	
	return sample.cpuUsage >= 0.9 ? NSColor.warning3Color : sample.cpuUsage >= 0.8 ? NSColor.warning2Color : sample.cpuUsage >= 0.7 ? NSColor.warningColor : NSColor.controlBackgroundColor;
}

- (NSString*)statusTooltipforItem:(id)item
{
	DTXReactNativePeroformanceSample* sample = item;
	
	return sample.cpuUsage >= 0.9 ? NSLocalizedString(@"JavaScript thread usage above 90%", @"") : sample.cpuUsage >= 0.8 ? NSLocalizedString(@"JavaScript thread usage above 80%", @"") : sample.cpuUsage >= 0.7 ? NSLocalizedString(@"JavaScript thread usage above 70%", @"") : nil;
}

@end
