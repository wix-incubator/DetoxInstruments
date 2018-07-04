//
//  DTXSignpostCategoryProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostCategoryProxy.h"
#import "DTXSignpostNameProxy.h"
#import "DTXSignpostSample+UIExtensions.h"

@implementation DTXSignpostCategoryProxy

@synthesize duration=_duration;
@synthesize minDuration=_minDuration;
@synthesize avgDuration=_avgDuration;
@synthesize maxDuration=_maxDuration;
@synthesize stddevDuration=_stddevDuration;

- (instancetype)initWithCategory:(NSString *)category recording:(DTXRecording *)recording outlineView:(NSOutlineView *)outlineView
{
	self = [super initWithKeyPath:@"name" isRoot:NO recording:recording outlineView:outlineView];
	
	if(self)
	{
		_category = category;
	}
	
	return self;
}

- (Class)sampleClass
{
	return DTXSignpostSample.class;
}

- (id)objectForSample:(id)sample
{
	return [[DTXSignpostNameProxy alloc] initWithCategory:self.category name:sample recording:self.recording outlineView:self.outlineView];
}

- (NSString *)name
{
	return _category;
}

- (NSPredicate *)predicateForAggregator
{
	return [NSPredicate predicateWithFormat:@"category == %@", _category];
}

- (NSUInteger)count
{
	return self.fetchedResultsController.fetchedObjects.count;
}

- (void)reloadData
{
	[super reloadData];
	
	[self _reloadDurations];
}

- (void)_reloadDurations
{
	NSFetchRequest* fr = DTXSignpostSample.fetchRequest;
	fr.predicate = self.predicateForAggregator;
	fr.resultType = NSDictionaryResultType;
	
	NSExpressionDescription* min = [NSExpressionDescription new];
	min.name = @"min";
	min.expression = [NSExpression expressionForFunction:@"min:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
	min.expressionResultType = NSDoubleAttributeType;
	
	NSExpressionDescription* avg = [NSExpressionDescription new];
	avg.name = @"avg";
	avg.expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
	avg.expressionResultType = NSDoubleAttributeType;
	
	NSExpressionDescription* stddev = [NSExpressionDescription new];
	stddev.name = @"duration";
	stddev.expression = [NSExpression expressionForFunction:@"sum:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
	stddev.expressionResultType = NSDoubleAttributeType;
	
	NSExpressionDescription* max = [NSExpressionDescription new];
	max.name = @"max";
	max.expression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
	max.expressionResultType = NSDoubleAttributeType;
	
	fr.propertiesToFetch = @[min, avg, stddev, max];
	NSDictionary<NSString*, NSNumber*>* results = [self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject;
	
	_duration = results[@"duration"].doubleValue;
	_minDuration = results[@"min"].doubleValue;
	_avgDuration = results[@"avg"].doubleValue;
	_maxDuration = results[@"max"].doubleValue;
}

@end
