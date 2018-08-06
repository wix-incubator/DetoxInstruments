//
//  DTXSignpostNameProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostNameProxy.h"
#import "DTXSignpostSample+UIExtensions.h"

@implementation DTXSignpostNameProxy

@synthesize name=_name;
@synthesize fetchRequest=_fetchRequest;
@synthesize duration=_duration;
@synthesize minDuration=_minDuration;
@synthesize avgDuration=_avgDuration;
@synthesize maxDuration=_maxDuration;
@synthesize stddevDuration=_stddevDuration;

- (instancetype)initWithCategory:(NSString*)category name:(NSString*)name recording:(DTXRecording*)recording outlineView:(NSOutlineView*)outlineView
{
	self = [super initWithOutlineView:outlineView isRoot:NO managedObjectContext:recording.managedObjectContext];
	
	if(self)
	{
		_category = category;
		_name = name;
		
		_fetchRequest = DTXSignpostSample.fetchRequest;
		_fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@ && name == %@", _category, _name];
		_fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	}
	
	return self;
}

- (void)reloadData
{
	[super reloadData];
	
	[self _reloadDurations];
}

- (void)_reloadDurations
{
	NSFetchRequest* fr = DTXSignpostSample.fetchRequest;
	
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"endTimestamp != nil"], _fetchRequest.predicate]];
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

- (NSUInteger)count
{
	return self.fetchedResultsController.fetchedObjects.count;
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
