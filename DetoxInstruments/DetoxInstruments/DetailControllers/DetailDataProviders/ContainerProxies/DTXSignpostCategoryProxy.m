//
//  DTXSignpostCategoryProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXSignpostCategoryProxy.h"
#import "DTXSignpostNameProxy.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXSample+Additions.h"
#import "NSString+Hashing.h"

@implementation DTXSignpostCategoryProxy
{
	NSDictionary<NSString*, NSDictionary*>* _nameProxyInfo;
}

@synthesize duration=_duration;
@synthesize minDuration=_minDuration;
@synthesize avgDuration=_avgDuration;
@synthesize maxDuration=_maxDuration;
@synthesize stddevDuration=_stddevDuration;
@synthesize timestamp=_timestamp;
@synthesize endTimestamp=_endTimestamp;
@synthesize isEvent=_isEvent;
@synthesize count=_count;

- (instancetype)initWithCategory:(NSString*)category managedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView
{
	self = [super initWithKeyPath:@"name" outlineView:outlineView managedObjectContext:managedObjectContext isRoot:NO];
	
	if(self)
	{
		_category = category;
		
		[self _reloadDurations];
		[self _reloadNameProxyInfo];
	}
	
	return self;
}

- (Class)sampleClass
{
	return DTXSignpostSample.class;
}

- (id)objectForSample:(id)sample
{
	NSDictionary* proxyInfo = _nameProxyInfo[sample];
	
	return [[DTXSignpostNameProxy alloc] initWithCategory:self.category name:sample info:proxyInfo managedObjectContext:self.managedObjectContext outlineView:self.outlineView];
}

- (NSString *)name
{
	return _category;
}

- (NSPredicate *)predicateForAggregator
{
	return [NSPredicate predicateWithFormat:@"categoryHash == %@ && hidden == NO", _category.sufficientHash];
}

- (void)prepareData
{
	[super prepareData];
}

- (void)_reloadDurations
{
	NSFetchRequest* fr = DTXSignpostSample.fetchRequest;
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"endTimestamp != nil && isEvent == NO"], self.predicateForAggregator]];
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
	NSDictionary<NSString*, id>* results = [self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject;
	
	_minDuration = [results[@"min"] doubleValue];
	_avgDuration = [results[@"avg"] doubleValue];
	_maxDuration = [results[@"max"] doubleValue];
	_timestamp = results[@"timestamp"];
	_endTimestamp = results[@"endTimestamp"];
	_duration = [_endTimestamp timeIntervalSinceDate:_timestamp];
	
	fr.predicate = self.predicateForAggregator;
	fr.propertiesToFetch = @[@"nameHash"];
	
	_count = [self.managedObjectContext countForFetchRequest:fr error:NULL];
	NSUInteger countSome = [results[@"countIsEvent"] unsignedIntegerValue];

	_isEvent = _count == countSome;
}

- (void)_reloadNameProxyInfo
{
	NSFetchRequest* fr = DTXSignpostSample.fetchRequest;
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"endTimestamp != nil && isEvent == NO"], self.predicateForAggregator]];
	fr.resultType = NSDictionaryResultType;
	fr.propertiesToGroupBy = @[@"name"];
	
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
	
	NSExpression *nameExpression = [NSExpression expressionForKeyPath:@"name"];
	NSExpressionDescription *nameDescription = [NSExpressionDescription new];
	nameDescription.expression = nameExpression;
	nameDescription.name = @"name";
	nameDescription.expressionResultType = NSStringAttributeType;
	
	fr.propertiesToFetch = @[min, avg, max, minTimestamp, maxTimestamp, countIsEvent, nameDescription];
	
	NSMutableDictionary* nameProxyInfo = [NSMutableDictionary new];
	
	NSArray<NSDictionary*>* results = [self.managedObjectContext executeFetchRequest:fr error:NULL];
	
	NSExpressionDescription* countAll = [NSExpressionDescription new];
	countAll.name = @"countAll";
	countAll.expression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"timestamp"]]];
	countAll.expressionResultType = NSInteger64AttributeType;
	
	fr.predicate = self.predicateForAggregator;
	fr.propertiesToFetch = @[countAll];
	
	NSArray<NSDictionary*>* countAllResults = [self.managedObjectContext executeFetchRequest:fr error:NULL];
	
	[results enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMutableDictionary* _obj = [[NSMutableDictionary alloc] initWithDictionary:obj];
		_obj[@"countAll"] = countAllResults[idx][@"countAll"];
		nameProxyInfo[obj[@"name"]] = _obj;
	}];
	
	_nameProxyInfo = nameProxyInfo;
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
