//
//  DTXMemoryDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXMemoryDataProvider.h"

@implementation DTXMemoryDataProvider

- (NSArray<NSString *> *)columnTitles
{
	return @[NSLocalizedString(@"Memory Usage", @"")];
}

- (DTXSampleType)sampleType
{
	return DTXSampleTypePerformance;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item memoryUsage])];
}

@end
