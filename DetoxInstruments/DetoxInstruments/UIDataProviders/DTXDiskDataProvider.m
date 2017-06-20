//
//  DTXDiskDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDiskDataProvider.h"

@implementation DTXDiskDataProvider

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* reads = [DTXColumnInformation new];
	reads.title = NSLocalizedString(@"Data Read", @"");
	reads.minWidth = 70;
	
	DTXColumnInformation* writes = [DTXColumnInformation new];
	writes.title = NSLocalizedString(@"Data Written", @"");
	writes.minWidth = 70;
	
	DTXColumnInformation* readsDelta = [DTXColumnInformation new];
	readsDelta.title = NSLocalizedString(@"Read (Delta)", @"");
	readsDelta.minWidth = 70;
	
	DTXColumnInformation* writesDelta = [DTXColumnInformation new];
	writesDelta.title = NSLocalizedString(@"Written (Delta)", @"");
	writesDelta.minWidth = 70;
	
	return @[reads, writes, readsDelta, writesDelta];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypePerformance), @(DTXSampleTypeAdvancedPerformance)];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 0:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskReads])];
		case 1:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskWrites])];
		case 2:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskReadsDelta])];
		case 3:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskWritesDelta])];
		default:
			return @"";
	}
}

@end
