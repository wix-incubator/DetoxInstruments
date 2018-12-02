//
//  DTXSampleDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSampleDataExporter.h"

@implementation DTXSampleDataExporter

- (NSFetchRequest *)fetchRequest
{
	NSFetchRequest* fr = [DTXPerformanceSample fetchRequest];
	fr.predicate = [NSPredicate predicateWithFormat:@"hidden == NO && sampleType in %@", @[@(DTXSampleTypePerformance), @(DTXSampleTypeAdvancedPerformance)]];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

@end
