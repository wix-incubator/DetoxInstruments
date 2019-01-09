//
//  DTXDiskDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
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
	reads.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"diskReads" ascending:YES];
	
	DTXColumnInformation* writes = [DTXColumnInformation new];
	writes.title = NSLocalizedString(@"Written (Total)", @"");
	writes.minWidth = 80;
	writes.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"diskWrites" ascending:YES];
	
	DTXColumnInformation* readsDelta = [DTXColumnInformation new];
	readsDelta.title = NSLocalizedString(@"Read (Delta)", @"");
	readsDelta.minWidth = 80;
	readsDelta.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"diskReadsDelta" ascending:YES];
	
	DTXColumnInformation* writesDelta = [DTXColumnInformation new];
	writesDelta.title = NSLocalizedString(@"Written (Delta)", @"");
	writesDelta.minWidth = 80;
	writesDelta.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"diskWritesDelta" ascending:YES];
	
	return @[readsDelta, writesDelta, reads, writes];
}

- (Class)sampleClass
{
	return DTXPerformanceSample.class;
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
