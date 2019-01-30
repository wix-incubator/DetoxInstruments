//
//  DTXSignpostCategoryProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSignpostCategoryProxy.h"
#import "DTXSignpostNameProxy.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXSample+Additions.h"
#import "NSString+Hashing.h"

@implementation DTXSignpostCategoryProxy

@synthesize duration=_duration;
@synthesize minDuration=_minDuration;
@synthesize avgDuration=_avgDuration;
@synthesize maxDuration=_maxDuration;
@synthesize stddevDuration=_stddevDuration;
@synthesize timestamp=_timestamp;
@synthesize endTimestamp=_endTimestamp;
@synthesize isEvent=_isEvent;

- (instancetype)initWithCategory:(NSString*)category managedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView
{
	self = [super initWithKeyPath:@"name" outlineView:outlineView managedObjectContext:managedObjectContext isRoot:NO];
	
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
	return [[DTXSignpostNameProxy alloc] initWithCategory:self.category name:sample managedObjectContext:self.managedObjectContext outlineView:self.outlineView];
}

- (NSString *)name
{
	return _category;
}

- (NSPredicate *)predicateForAggregator
{
	return [NSPredicate predicateWithFormat:@"categoryHash == %@ && hidden == NO", [_category MD5Hash]];
}

- (NSUInteger)count
{
	return self.fetchedResultsController.fetchedObjects.count;
}

- (void)prepareData
{
	[super prepareData];
	
	[self _reloadDurations];
	
	NSFetchRequest* fr = DTXSignpostSample.fetchRequest;
	fr.predicate = self.predicateForAggregator;
	fr.resultType = NSDictionaryResultType;
//	fr.propertiesToGroupBy = @[@"name"];
	
//	NSExpressionDescription* min = [NSExpressionDescription new];
//	min.name = @"min";
//	min.expression = [NSExpression expressionForFunction:@"min:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
//	min.expressionResultType = NSDoubleAttributeType;
//
//	NSExpressionDescription* avg = [NSExpressionDescription new];
//	avg.name = @"avg";
//	avg.expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
//	avg.expressionResultType = NSDoubleAttributeType;
//
//	NSExpressionDescription* max = [NSExpressionDescription new];
//	max.name = @"max";
//	max.expression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
//	max.expressionResultType = NSDoubleAttributeType;
//
//	NSExpressionDescription* minTimestamp = [NSExpressionDescription new];
//	minTimestamp.name = @"timestamp";
//	minTimestamp.expression = [NSExpression expressionForFunction:@"min:" arguments:@[[NSExpression expressionForKeyPath:@"timestamp"]]];
//	minTimestamp.expressionResultType = NSDateAttributeType;
//
//	NSExpressionDescription* maxTimestamp = [NSExpressionDescription new];
//	maxTimestamp.name = @"endTimestamp";
//	maxTimestamp.expression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForKeyPath:@"endTimestamp"]]];
//	maxTimestamp.expressionResultType = NSDateAttributeType;
//
//	NSExpressionDescription* countAll = [NSExpressionDescription new];
//	countAll.name = @"countAll";
//	countAll.expression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"timestamp"]]];
//	countAll.expressionResultType = NSInteger64AttributeType;
//
//	NSExpressionDescription* countIsEvent = [NSExpressionDescription new];
//	countIsEvent.name = @"countIsEvent";
//	countIsEvent.expression = [NSExpression expressionForFunction:@"sum:" arguments:@[[NSExpression expressionForKeyPath:@"isEvent"]]];
//	countIsEvent.expressionResultType = NSInteger64AttributeType;
	
//	fr.propertiesToFetch = @[min, avg, max, minTimestamp, maxTimestamp, countAll, countIsEvent];
	id results = [self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject;
	NSLog(@"");
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
	
	NSExpressionDescription* max = [NSExpressionDescription new];
	max.name = @"max";
	max.expression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForKeyPath:@"duration"]]];
	max.expressionResultType = NSDoubleAttributeType;
	
	NSExpressionDescription* minTimestamp = [NSExpressionDescription new];
	minTimestamp.name = @"timestamp";
	minTimestamp.expression = [NSExpression expressionForFunction:@"min:" arguments:@[[NSExpression expressionForKeyPath:@"timestamp"]]];
	minTimestamp.expressionResultType = NSDateAttributeType;
	
	NSExpressionDescription* maxTimestamp = [NSExpressionDescription new];
	maxTimestamp.name = @"endTimestamp";
	maxTimestamp.expression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForKeyPath:@"endTimestamp"]]];
	maxTimestamp.expressionResultType = NSDateAttributeType;
	
	NSExpressionDescription* countAll = [NSExpressionDescription new];
	countAll.name = @"countAll";
	countAll.expression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"timestamp"]]];
	countAll.expressionResultType = NSInteger64AttributeType;
	
	NSExpressionDescription* countIsEvent = [NSExpressionDescription new];
	countIsEvent.name = @"countIsEvent";
	countIsEvent.expression = [NSExpression expressionForFunction:@"sum:" arguments:@[[NSExpression expressionForKeyPath:@"isEvent"]]];
	countIsEvent.expressionResultType = NSInteger64AttributeType;
	
	fr.propertiesToFetch = @[min, avg, max, minTimestamp, maxTimestamp, countAll, countIsEvent];
	NSDictionary<NSString*, id>* results = [self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject;
	
	_minDuration = [results[@"min"] doubleValue];
	_avgDuration = [results[@"avg"] doubleValue];
	_maxDuration = [results[@"max"] doubleValue];
	_timestamp = results[@"timestamp"];
	_endTimestamp = results[@"endTimestamp"];
	_duration = [_endTimestamp timeIntervalSinceDate:_timestamp];
	
	NSUInteger count = [results[@"countAll"] unsignedIntegerValue];
	NSUInteger countSome = [results[@"countIsEvent"] unsignedIntegerValue];
	
	_isEvent = count == countSome;
}

- (NSDate *)defactoEndTimestamp
{
	return _endTimestamp;
}

- (BOOL)isExpandable
{
	return YES;
}

@end
