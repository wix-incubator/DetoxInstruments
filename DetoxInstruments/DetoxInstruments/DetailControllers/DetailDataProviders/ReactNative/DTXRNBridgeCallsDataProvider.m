//
//  DTXRNBridgeCallsDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/08/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXRNBridgeCallsDataProvider.h"
#import "DTXRNBridgeCallsInspectorDataProvider.h"
#import "DTXRNBridgeCountersDataExporter.h"

@implementation DTXRNBridgeCallsDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXRNBridgeCallsInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXRNBridgeCountersDataExporter.class;
}

- (Class)sampleClass
{
	return DTXReactNativePerformanceSample.class;
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* reads = [DTXColumnInformation new];
	reads.title = NSLocalizedString(@"N → JS (Total)", @"");
	reads.minWidth = 90;
	reads.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeNToJSCallCount" ascending:YES];
	
	DTXColumnInformation* writes = [DTXColumnInformation new];
	writes.title = NSLocalizedString(@"JS → N (Total)", @"");
	writes.minWidth = 90;
	writes.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeJSToNCallCount" ascending:YES];
	
	DTXColumnInformation* readsDelta = [DTXColumnInformation new];
	readsDelta.title = NSLocalizedString(@"N → JS (Delta)", @"");
	readsDelta.minWidth = 90;
	readsDelta.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeNToJSCallCountDelta" ascending:YES];
	
	DTXColumnInformation* writesDelta = [DTXColumnInformation new];
	writesDelta.title = NSLocalizedString(@"JS → N (Delta)", @"");
	writesDelta.minWidth = 90;
	writesDelta.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"bridgeJSToNCallCountDelta" ascending:YES];
	
	return @[readsDelta, writesDelta, reads, writes];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 0:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePerformanceSample*)item bridgeNToJSCallCountDelta])];
		case 1:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePerformanceSample*)item bridgeJSToNCallCountDelta])];
		case 2:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePerformanceSample*)item bridgeNToJSCallCount])];
		case 3:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePerformanceSample*)item bridgeJSToNCallCount])];
		default:
			return @"";
	}
}

@end
