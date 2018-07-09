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
	NSMutableDictionary<NSString*, DTXSampleContainerProxy*>* _proxyMapping;
}

- (instancetype)initWithKeyPath:(NSString*)keyPath isRoot:(BOOL)root recording:(DTXRecording*)recording outlineView:(NSOutlineView*)outlineView
{
	self = [super initWithOutlineView:outlineView isRoot:root managedObjectContext:recording.managedObjectContext];
	
	if(self)
	{
		_keyPath = keyPath;
		_recording = recording;
	}
	
	return self;
}

- (void)reloadData
{
	NSFetchRequest* fr = [self _fetchRequestForAggregatesWithRecording:_recording dictionaryResult:YES];
	id categories = [_recording.managedObjectContext executeFetchRequest:fr error:NULL];
	
	_aggregates = [categories valueForKey:self.keyPath];
	_proxyMapping = [NSMutableDictionary new];
	
	[_aggregates enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		_proxyMapping[obj] = [self objectForSample:obj];
	}];
	
	[super reloadData];
}

- (NSFetchRequest *)fetchRequest
{
	return [self _fetchRequestForAggregatesWithRecording:_recording dictionaryResult:NO];
}

- (NSFetchRequest*)_fetchRequestForAggregatesWithRecording:(DTXRecording*)recording dictionaryResult:(BOOL)dictionaryResult
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
{
	
}

- (NSUInteger)samplesCount
{
	return _aggregates.count;
}

- (id)sampleAtIndex:(NSUInteger)index
{
	return _proxyMapping[_aggregates[index]];
}


@end
