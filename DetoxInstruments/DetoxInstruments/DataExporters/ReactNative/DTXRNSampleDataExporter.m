//
//  DTXRNSampleDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNSampleDataExporter.h"

@implementation DTXRNSampleDataExporter

- (NSFetchRequest *)fetchRequest
{
	NSFetchRequest* fr = [DTXReactNativePerformanceSample fetchRequest];
	fr.predicate = [NSPredicate predicateWithFormat:@"hidden == NO && sampleType in %@", @[@(DTXSampleTypeReactNativePerformanceType)]];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

@end
