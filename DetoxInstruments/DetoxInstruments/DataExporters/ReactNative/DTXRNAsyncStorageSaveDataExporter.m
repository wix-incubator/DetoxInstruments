//
//  DTXRNAsyncStorageSaveDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/27/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNAsyncStorageSaveDataExporter.h"

@implementation DTXRNAsyncStorageSaveDataExporter

- (NSFetchRequest *)fetchRequest
{
	NSFetchRequest* fr = [DTXReactNativeAsyncStorageSample fetchRequest];
	fr.predicate = [NSPredicate predicateWithFormat:@"hidden == NO"];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"saveDuration", @"operation", @"saveCount"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Time", @"Save Duration", @"Operation", @"Save Count"];
}

@end
