//
//  DTXRNAsyncStorageFetchesDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/26/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNAsyncStorageFetchesDataProvider.h"
#import "DTXRNAsyncStorageInspectorDataProvider.h"
#import "DTXRNAsyncStorageFetchDataExporter.h"

@implementation DTXRNAsyncStorageFetchesDataProvider

+ (Class)inspectorDataProviderClass
{
	return DTXRNAsyncStorageInspectorDataProvider.class;
}

- (Class)dataExporterClass
{
	return DTXRNAsyncStorageFetchDataExporter.class;
}

- (Class)sampleClass
{
	return DTXReactNativeAsyncStorageSample.class;
}

- (NSString *)identifier
{
	return @"AsyncStorageFetches";
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Fetches", @"");
}

- (NSImage *)displayIcon
{
	NSImage* image = [NSImage imageNamed:@"RNAsyncStorageFetches"];
	image.size = NSMakeSize(16, 16);

	return image;
}

- (NSPredicate *)predicateForSamples
{
	return [NSPredicate predicateWithFormat:@"fetchDuration > 0.0"];
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* fetchDuration = [DTXColumnInformation new];
	fetchDuration.title = NSLocalizedString(@"Fetch Duration", @"");
	fetchDuration.minWidth = 90;
	fetchDuration.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fetchDuration" ascending:YES];
	
	DTXColumnInformation* operation = [DTXColumnInformation new];
	operation.title = NSLocalizedString(@"Operation", @"");
	operation.minWidth = 120;
	operation.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"operation" ascending:YES];
	
	DTXColumnInformation* fetchCount = [DTXColumnInformation new];
	fetchCount.title = NSLocalizedString(@"Fetch Count", @"");
	fetchCount.minWidth = 90;
	fetchCount.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fetchCount" ascending:YES];
	
	return @[fetchDuration, operation, fetchCount];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 0:
			return [[NSFormatter dtx_durationFormatter] stringFromTimeInterval:[(DTXReactNativeAsyncStorageSample*)item fetchDuration]];
		case 1:
			return [(DTXReactNativeAsyncStorageSample*)item operation];
		case 2:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativeAsyncStorageSample*)item fetchCount])];
		default:
			return @"";
	}
}

- (NSColor*)backgroundRowColorForItem:(id)item
{
	if([(DTXReactNativeAsyncStorageSample*)item data].error != nil)
	{
		return NSColor.warning3Color;
	}
	
	return NSColor.controlBackgroundColor;
}

@end
