//
//  DTXMemoryDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXMemoryDataProvider.h"
#import "DTXMemoryInspectorDataProvider.h"
#import "DTXMemoryUsageDataExporter.h"

@implementation DTXMemoryDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXMemoryInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXMemoryUsageDataExporter.class;
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* info = [DTXColumnInformation new];
	info.title = NSLocalizedString(@"Memory Usage", @"");
	info.minWidth = 75;
	info.automaticallyGrowsWithTable = YES;
	info.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"memoryUsage" ascending:YES];
	
	return @[info];
}

- (Class)sampleClass
{
	return DTXAdvancedPerformanceSample.class;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return [NSFormatter.dtx_memoryFormatter stringForObjectValue:@([(DTXPerformanceSample*)item memoryUsage])];
}

@end
