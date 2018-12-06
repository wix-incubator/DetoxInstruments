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
#import "DTXSample+Additions.h"

@implementation DTXSignpostCategoryProxy

@synthesize duration=_duration;
@synthesize minDuration=_minDuration;
@synthesize avgDuration=_avgDuration;
@synthesize maxDuration=_maxDuration;
@synthesize stddevDuration=_stddevDuration;

- (instancetype)initWithCategory:(NSString*)category managedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView
{
	self = [super initWithKeyPath:@"name" isRoot:NO managedObjectContext:managedObjectContext outlineView:outlineView];
	
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
	return [NSPredicate predicateWithFormat:@"category == %@", _category];
}

- (NSUInteger)count
{
	return self.fetchedResultsController.fetchedObjects.count;
}

- (void)prepareData
{
	[super prepareData];
	
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

- (DTXRecording*)recording
{
	NSFetchRequest* fr = DTXSignpostSample.fetchRequest;
	fr.predicate = self.fetchRequest.predicate;
	NSArray<DTXSample*>* events = [self.fetchedResultsController.managedObjectContext executeFetchRequest:fr error:NULL];
	
	DTXRecording* rv = events.firstObject.recording;
	
	for(DTXSample* sample in events)
	{
		DTXRecording* pending = sample.recording;
		if([pending.startTimestamp compare:rv.startTimestamp] == NSOrderedDescending)
		{
			rv = pending;
		}
	}
	
	return rv;
}

- (NSDate *)closeTimestamp
{
	DTXSignpostSample* sample = self.fetchedResultsController.fetchedObjects.lastObject;
	
	return sample.endTimestamp;
}

- (BOOL)isGroup
{
	return YES;
}

- (BOOL)isEvent
{
	return NO;
}

@end
