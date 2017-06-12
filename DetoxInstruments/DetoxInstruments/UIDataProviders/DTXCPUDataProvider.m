//
//  DTXCPUDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCPUDataProvider.h"

@implementation DTXCPUDataProvider

- (NSArray<NSString *> *)columnTitles
{
	return @[NSLocalizedString(@"CPU Usage", @"")];
}

- (DTXSampleType)sampleType
{
	return DTXSampleTypePerformance;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return [[NSFormatter dtx_percentFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item cpuUsage])];
}

@end
