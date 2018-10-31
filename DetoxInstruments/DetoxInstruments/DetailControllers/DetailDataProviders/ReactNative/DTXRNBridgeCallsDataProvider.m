//
//  DTXRNBridgeCallsDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRNBridgeCallsDataProvider.h"
#import "DTXRNBridgeCallsInspectorDataProvider.h"

@implementation DTXRNBridgeCallsDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXRNBridgeCallsInspectorDataProvider class];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypeReactNativePerformanceType)];
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* reads = [DTXColumnInformation new];
	reads.title = NSLocalizedString(@"N → JS (Total)", @"");
	reads.minWidth = 80;
	
	DTXColumnInformation* writes = [DTXColumnInformation new];
	writes.title = NSLocalizedString(@"JS → N (Total)", @"");
	writes.minWidth = 80;
	
	DTXColumnInformation* readsDelta = [DTXColumnInformation new];
	readsDelta.title = NSLocalizedString(@"N → JS (Delta)", @"");
	readsDelta.minWidth = 80;
	
	DTXColumnInformation* writesDelta = [DTXColumnInformation new];
	writesDelta.title = NSLocalizedString(@"JS → N (Delta)", @"");
	writesDelta.minWidth = 80;
	
	return @[readsDelta, writesDelta, reads, writes];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 0:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeNToJSCallCountDelta])];
		case 1:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeJSToNCallCountDelta])];
		case 2:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeNToJSCallCount])];
		case 3:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativePeroformanceSample*)item bridgeJSToNCallCount])];
		default:
			return @"";
	}
}

@end
