//
//  DTXPerformanceSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPerformanceSamplePlotController.h"
#import "DTXPerformanceSample+CoreDataClass.h"

@implementation DTXPerformanceSamplePlotController

- (NSArray<NSArray *> *)samplesForPlots
{
	NSMutableArray* rv = [NSMutableArray new];
	
	if(self.document == nil)
	{
		return @[];
	}
	
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sampleKey, NSUInteger idx, BOOL * _Nonnull stop) {
		NSFetchRequest* fr = [self.classForPerformanceSamples fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		fr.predicate = self.predicateForPerformanceSamples;
		
		NSError* error = nil;
		NSArray* results = [self.document.recording.managedObjectContext executeFetchRequest:fr error:&error];
		
		if(results == nil)
		{
			*stop = YES;
			return;
		}
		
		[rv addObject:results];
	}];
	
	if(rv.count != self.sampleKeys.count)
	{
		return nil;
	}
	
	return rv;
}

- (NSPredicate*)predicateForPerformanceSamples
{
	return [NSPredicate predicateWithFormat:@"NOT(sampleType IN %@)", @[@(DTXSampleTypeThreadPerformance)]];
}

- (Class)classForPerformanceSamples
{
	return [DTXPerformanceSample class];
}

@end
