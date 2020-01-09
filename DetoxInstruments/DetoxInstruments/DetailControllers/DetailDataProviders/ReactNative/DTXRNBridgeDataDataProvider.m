//
//  DTXRNBridgeDataDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/08/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNBridgeDataDataProvider.h"
#import "DTXRNBridgeDataInspectorDataProvider.h"
#import "DTXRNBridgeDataDataExporter.h"

@implementation DTXRNBridgeDataDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXRNBridgeDataInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXRNBridgeDataDataExporter.class;
}

- (Class)sampleClass
{
	return DTXReactNativePeroformanceSample.class;
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* reads = [DTXColumnInformation new];
	reads.title = NSLocalizedString(@"N → JS (Total)", @"");
	reads.minWidth = 90;
	reads.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeNToJSDataSize" ascending:YES];
	
	DTXColumnInformation* writes = [DTXColumnInformation new];
	writes.title = NSLocalizedString(@"JS → N (Total)", @"");
	writes.minWidth = 90;
	writes.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeJSToNDataSize" ascending:YES];
	
	DTXColumnInformation* readsDelta = [DTXColumnInformation new];
	readsDelta.title = NSLocalizedString(@"N → JS (Delta)", @"");
	readsDelta.minWidth = 90;
	readsDelta.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeNToJSDataSizeDelta" ascending:YES];
	
	DTXColumnInformation* writesDelta = [DTXColumnInformation new];
	writesDelta.title = NSLocalizedString(@"JS → N (Delta)", @"");
	writesDelta.minWidth = 90;
	writesDelta.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeJSToNDataSizeDelta" ascending:YES];
	
	return @[readsDelta, writesDelta, reads, writes];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 0:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeNToJSDataSizeDelta])];
		case 1:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeJSToNDataSizeDelta])];
		case 2:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeNToJSDataSize])];
		case 3:
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeJSToNDataSize])];
		default:
			return @"";
	}
}

@end
