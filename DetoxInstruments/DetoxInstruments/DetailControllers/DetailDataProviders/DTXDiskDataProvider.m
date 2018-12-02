//
//  DTXDiskDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDiskDataProvider.h"
#import "DTXDiskInspectorDataProvider.h"
#import "DTXDiskActivityDataExporter.h"

@implementation DTXDiskDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXDiskInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXDiskActivityDataExporter.class;
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* reads = [DTXColumnInformation new];
	reads.title = NSLocalizedString(@"Read (Total)", @"");
	reads.minWidth = 80;
	
	DTXColumnInformation* writes = [DTXColumnInformation new];
	writes.title = NSLocalizedString(@"Written (Total)", @"");
	writes.minWidth = 80;
	
	DTXColumnInformation* readsDelta = [DTXColumnInformation new];
	readsDelta.title = NSLocalizedString(@"Read (Delta)", @"");
	readsDelta.minWidth = 80;
	
	DTXColumnInformation* writesDelta = [DTXColumnInformation new];
	writesDelta.title = NSLocalizedString(@"Written (Delta)", @"");
	writesDelta.minWidth = 80;
	
	return @[readsDelta, writesDelta, reads, writes];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypePerformance), @(DTXSampleTypeAdvancedPerformance)];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 2:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskReads])];
		case 3:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskWrites])];
		case 0:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskReadsDelta])];
		case 1:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskWritesDelta])];
		default:
			return @"";
	}
}

@end
