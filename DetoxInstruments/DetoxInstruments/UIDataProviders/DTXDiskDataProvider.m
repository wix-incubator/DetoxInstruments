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
	reads.title = NSLocalizedString(@"Reads (Total)", @"");
	reads.minWidth = 65;
	
	DTXColumnInformation* writes = [DTXColumnInformation new];
	writes.title = NSLocalizedString(@"Writes (Total)", @"");
	writes.minWidth = 65;
	
	DTXColumnInformation* readsDelta = [DTXColumnInformation new];
	readsDelta.title = NSLocalizedString(@"Reads (Delta)", @"");
	readsDelta.minWidth = 65;
	
	DTXColumnInformation* writesDelta = [DTXColumnInformation new];
	writesDelta.title = NSLocalizedString(@"Writes (Delta)", @"");
	writesDelta.minWidth = 65;
	
	return @[readsDelta, writesDelta, reads, writes];
}

- (DTXSampleType)sampleType
{
	return DTXSampleTypePerformance;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 0:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskReadsDelta])];
		case 1:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskWritesDelta])];
		case 2:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskReads])];
		case 3:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXPerformanceSample*)item diskWrites])];
		default:
			return @"";
	}
}

@end
