//
//  DTXSignpostDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXSignpostDataExporter.h"
#import "DTXSignpostSample+UIExtensions.h"

@implementation DTXSignpostDataExporter

- (NSFetchRequest *)fetchRequest
{
	NSFetchRequest* fr = [DTXSignpostSample fetchRequest];
	fr.predicate = [NSPredicate predicateWithFormat:@"hidden == NO && sampleType in %@", @[@(DTXSampleTypeSignpost)]];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"endTimestamp", @"duration", @"eventTypeString", @"category", @"name", @"eventStatusString", @"additionalInfoStart", @"additionalInfoEnd"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Start Time", @"End Time", @"Duration", @"Type", @"Category", @"Name", @"Event Status", @"Start Message", @"End Message"];
}

@end
