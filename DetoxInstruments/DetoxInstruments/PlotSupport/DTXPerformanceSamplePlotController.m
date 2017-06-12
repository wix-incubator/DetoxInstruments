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

- (NSArray<NSArray<NSDictionary<NSString*, id>*>*>*)samplesForPlots
{
	NSMutableArray* rv = [NSMutableArray new];
	
	if(DTXPerformanceSample.entity == nil)
	{
		return @[];
	}
	
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sampleKey, NSUInteger idx, BOOL * _Nonnull stop) {
		NSFetchRequest* fr = [DTXPerformanceSample fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		fr.resultType = NSDictionaryResultType;
		 
		fr.propertiesToGroupBy = @[DTXPerformanceSample.entity.attributesByName[@"timestamp"]];
		
		NSExpressionDescription* sum = [NSExpressionDescription new];
		sum.name = [NSString stringWithFormat:@"%@", sampleKey];
		sum.expression = [NSExpression expressionForKeyPath:[NSString stringWithFormat:@"@sum.%@", sampleKey]];
		sum.expressionResultType = NSDecimalAttributeType;
		
		fr.propertiesToFetch = @[@"timestamp", sum];
		
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

@end
