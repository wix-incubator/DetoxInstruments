//
//  DTXSampleAggregatorProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSampleAggregatorProxy.h"

@implementation DTXSampleAggregatorProxy
{
	NSMutableArray<NSString*>* _aggregates;
	NSMapTable<NSString*, DTXSampleContainerProxy*>* _proxyMapping;
}

@synthesize managedObjectContext=_managedObjectContext;

- (instancetype)initWithKeyPath:(NSString*)keyPath isRoot:(BOOL)root managedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView;
{
	self = [super initWithOutlineView:outlineView isRoot:root managedObjectContext:managedObjectContext];
	
	if(self)
	{
		_keyPath = keyPath;
		_managedObjectContext = managedObjectContext;
	}
	
	return self;
}

- (void)prepareData
{
	NSFetchRequest* fr = [self _fetchRequestForAggregatesWithDictionaryResult:YES];
	id categories = [_managedObjectContext executeFetchRequest:fr error:NULL];
	
	_aggregates = [categories valueForKey:self.keyPath];
	_proxyMapping = [NSMapTable strongToStrongObjectsMapTable];
	
	[_aggregates enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		_proxyMapping[obj] = [self objectForSample:obj];
	}];
	
	[super prepareData];
}

- (NSFetchRequest *)fetchRequest
{
	return [self _fetchRequestForAggregatesWithDictionaryResult:NO];
}

- (NSFetchRequest*)_fetchRequestForAggregatesWithDictionaryResult:(BOOL)dictionaryResult
{
	NSFetchRequest* fr = [self.sampleClass fetchRequest];
	
	if(dictionaryResult)
	{
		NSExpression *nameExpression = [NSExpression expressionForKeyPath:self.keyPath];
		NSExpressionDescription *nameDescription = [NSExpressionDescription new];
		nameDescription.expression = nameExpression;
		nameDescription.name = self.keyPath;
		nameDescription.expressionResultType = NSStringAttributeType;
		
		fr.propertiesToFetch = @[nameDescription];
		fr.propertiesToGroupBy = @[self.keyPath];
		fr.resultType = NSDictionaryResultType;
	}
	
	fr.predicate = self.predicateForAggregator;
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

- (void)handleSampleInserts:(NSArray *)inserts updates:(NSArray *)updates shouldReloadProxy:(BOOL *)reloadProxy
{}

- (NSUInteger)samplesCount
{
	return _aggregates.count;
}

- (id)sampleAtIndex:(NSUInteger)index
{
	return _proxyMapping[_aggregates[index]];
}


@end
