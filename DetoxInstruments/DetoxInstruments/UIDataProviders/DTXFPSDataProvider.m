//
//  DTXFPSDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXFPSDataProvider.h"

@implementation DTXFPSDataProvider

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* info = [DTXColumnInformation new];
	info.title = NSLocalizedString(@"FPS", @"");
	info.minWidth = 20;
	
	return @[info];
}

- (DTXSampleType)sampleType
{
	return DTXSampleTypePerformance;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item fps])];
}

- (NSColor*)textColorForItem:(id)item
{
	return NSColor.blackColor;
}

- (NSColor*)backgroundRowColorForItem:(id)item
{
	double fps = [(DTXPerformanceSample*)item fps];
	
	return fps < 15 ? NSColor.warning3Color : fps <= 30 ? NSColor.warning2Color : fps <= 45 ? NSColor.warningColor : NSColor.whiteColor;
}

@end
