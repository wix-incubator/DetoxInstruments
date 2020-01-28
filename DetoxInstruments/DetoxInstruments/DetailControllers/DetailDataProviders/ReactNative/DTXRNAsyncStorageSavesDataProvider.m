//
//  DTXRNAsyncStorageSavesDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/27/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNAsyncStorageSavesDataProvider.h"
#import "DTXRNAsyncStorageInspectorDataProvider.h"
#import "DTXRNAsyncStorageSaveDataExporter.h"

@implementation DTXRNAsyncStorageSavesDataProvider

+ (Class)inspectorDataProviderClass
{
	return DTXRNAsyncStorageInspectorDataProvider.class;
}

- (Class)dataExporterClass
{
	return DTXRNAsyncStorageSaveDataExporter.class;
}

- (Class)sampleClass
{
	return DTXReactNativeAsyncStorageSample.class;
}

- (NSString *)identifier
{
	return @"AsyncStorageSaves";
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Saves", @"");
}

- (NSImage *)displayIcon
{
	NSImage* image = [NSImage imageNamed:@"RNAsyncStorageSaves"];
	image.size = NSMakeSize(16, 16);

	return image;
}

- (NSPredicate *)predicateForSamples
{
	return [NSPredicate predicateWithFormat:@"saveDuration > 0.0"];
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* fetchDuration = [DTXColumnInformation new];
	fetchDuration.title = NSLocalizedString(@"Save Duration", @"");
	fetchDuration.minWidth = 90;
	fetchDuration.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"saveDuration" ascending:YES];
	
	DTXColumnInformation* operation = [DTXColumnInformation new];
	operation.title = NSLocalizedString(@"Operation", @"");
	operation.minWidth = 120;
	operation.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"operation" ascending:YES];
	
	DTXColumnInformation* fetchCount = [DTXColumnInformation new];
	fetchCount.title = NSLocalizedString(@"Save Count", @"");
	fetchCount.minWidth = 90;
	fetchCount.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"saveCount" ascending:YES];
	
	return @[fetchDuration, operation, fetchCount];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	switch(column)
	{
		case 0:
			return [[NSFormatter dtx_durationFormatter] stringFromTimeInterval:[(DTXReactNativeAsyncStorageSample*)item saveDuration]];
		case 1:
			return [(DTXReactNativeAsyncStorageSample*)item operation];
		case 2:
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@([(DTXReactNativeAsyncStorageSample*)item saveCount])];
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
