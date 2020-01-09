//
//  DTXSignpostNameProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXSignpostNameProxy.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXSample+Additions.h"
#import "NSString+Hashing.h"

@implementation DTXSignpostNameProxy
{
	NSFetchRequest* _fetchRequest;
	NSDictionary* _info;
}

@synthesize name=_name;
@synthesize duration=_duration;
@synthesize minDuration=_minDuration;
@synthesize avgDuration=_avgDuration;
@synthesize maxDuration=_maxDuration;
@synthesize stddevDuration=_stddevDuration;
@synthesize timestamp=_timestamp;
@synthesize endTimestamp=_endTimestamp;
@synthesize isEvent=_isEvent;
@synthesize count=_count;

- (instancetype)initWithCategory:(NSString*)category name:(NSString*)name info:(NSDictionary*)info managedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView
{
	self = [super initWithOutlineView:outlineView managedObjectContext:managedObjectContext isRoot:NO];
	
	if(self)
	{
		_category = category;
		_name = name;
		_info = info;
		
		_fetchRequest = DTXSignpostSample.fetchRequest;
		_fetchRequest.predicate = [NSPredicate predicateWithFormat:@"categoryHash == %@ && nameHash == %@ && hidden == NO", _category.sufficientHash, _name.sufficientHash];
		_fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		
		[self _reloadDurations];
	}
	
	return self;
}

- (void)prepareData
{
	[super prepareData];
}

- (id)objectForSample:(id)sample
{
	return sample;
}

- (NSFetchRequest *)fetchRequest
{
	return _fetchRequest;
}

- (void)_reloadDurations
{
	NSDictionary<NSString*, id>* results = _info;
	if(results == nil)
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
		
		NSExpressionDescription* countIsEvent = [NSExpressionDescription new];
		countIsEvent.name = @"countIsEvent";
		countIsEvent.expression = [NSExpression expressionForFunction:@"sum:" arguments:@[[NSExpression expressionForKeyPath:@"isEvent"]]];
		countIsEvent.expressionResultType = NSInteger64AttributeType;
		
		fr.propertiesToFetch = @[min, avg, max, minTimestamp, maxTimestamp, countIsEvent];
		NSMutableDictionary* rr = [NSMutableDictionary dictionaryWithDictionary:[self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject];
		
		rr[@"countAll"] = @([self.managedObjectContext countForFetchRequest:_fetchRequest error:NULL]);
		
		results = rr;
	}
	
	_minDuration = [results[@"min"] doubleValue];
	_avgDuration = [results[@"avg"] doubleValue];
	_maxDuration = [results[@"max"] doubleValue];
	_timestamp = results[@"timestamp"];
	_endTimestamp = results[@"endTimestamp"];
	_duration = [_endTimestamp timeIntervalSinceDate:_timestamp];
	
	NSUInteger count = [results[@"countAll"] unsignedIntegerValue];
	NSUInteger countSome = [results[@"countIsEvent"] unsignedIntegerValue];
	
	_count = count;
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
