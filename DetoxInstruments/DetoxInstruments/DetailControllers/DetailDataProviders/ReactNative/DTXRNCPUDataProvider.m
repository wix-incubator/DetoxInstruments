//
//  DTXRNCPUDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRNCPUDataProvider.h"
#import "DTXRNCPUInspectorDataProvider.h"

@implementation DTXRNCPUDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXRNCPUInspectorDataProvider class];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypeReactNativePerformanceType)];
}

- (NSString*)titleOfCPUHeader
{
	return NSLocalizedString(@"JavaScript Thread", @"");
}

- (BOOL)showsHeaviestThreadColumn
{
	return NO;
}

- (NSColor*)backgroundRowColorForItem:(id)item
{
	DTXReactNativePeroformanceSample* sample = item;
	
	return sample.cpuUsage >= 0.9 ? NSColor.warning3Color : sample.cpuUsage >= 0.8 ? NSColor.warning2Color : sample.cpuUsage >= 0.7 ? NSColor.warningColor : NSColor.controlBackgroundColor;
}


@end
