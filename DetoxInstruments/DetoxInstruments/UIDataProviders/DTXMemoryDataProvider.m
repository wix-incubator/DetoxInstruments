//
//  DTXMemoryDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXMemoryDataProvider.h"
#import "DTXMemoryInspectorDataProvider.h"

@implementation DTXMemoryDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXMemoryInspectorDataProvider class];
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* info = [DTXColumnInformation new];
	info.title = NSLocalizedString(@"Memory Usage", @"");
	info.minWidth = 75;
	
	return @[info];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypePerformance), @(DTXSampleTypeAdvancedPerformance)];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item memoryUsage])];
}

@end
