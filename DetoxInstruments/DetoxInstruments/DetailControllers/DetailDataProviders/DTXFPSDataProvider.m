//
//  DTXFPSDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXFPSDataProvider.h"
#import "DTXFPSInspectorDataProvider.h"
#import "DTXFPSDataExporter.h"

@implementation DTXFPSDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXFPSInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXFPSDataExporter.class;
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* info = [DTXColumnInformation new];
	info.title = NSLocalizedString(@"FPS", @"");
	info.minWidth = 20;
	info.automaticallyGrowsWithTable = YES;
	info.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fps" ascending:YES];
	
	return @[info];
}

- (Class)sampleClass
{
	return DTXAdvancedPerformanceSample.class;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return [NSFormatter.dtx_stringFormatter stringForObjectValue:@([(DTXPerformanceSample*)item fps])];
}

- (NSColor*)textColorForItem:(id)item
{
	return NSColor.labelColor;
}

- (NSColor*)backgroundRowColorForItem:(id)item
{
	double fps = [(DTXPerformanceSample*)item fps];
	
	return fps < 15 ? NSColor.warning3Color : fps <= 30 ? NSColor.warning2Color : fps <= 45 ? NSColor.warningColor : NSColor.controlBackgroundColor;
}

- (NSString*)statusTooltipforItem:(id)item
{
	double fps = [(DTXPerformanceSample*)item fps];
	
	return fps < 15 ? NSLocalizedString(@"FPS below 15", @"") : fps <= 30 ? NSLocalizedString(@"FPS below 30", @"") : fps <= 45 ? NSLocalizedString(@"FPS below 45", @"") : nil;
}

@end
