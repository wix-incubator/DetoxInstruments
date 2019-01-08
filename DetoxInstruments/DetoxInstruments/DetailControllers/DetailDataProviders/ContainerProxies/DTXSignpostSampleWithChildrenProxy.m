//
//  DTXSignpostSampleWithChildrenProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/7/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSignpostSampleWithChildrenProxy.h"
#import "DTXSignpostSample+UIExtensions.h"

@implementation DTXSignpostSampleWithChildrenProxy
{
	NSMutableArray<DTXSignpostSampleWithChildrenProxy*>* _children;
}

+ (void)_insertSample:(DTXSignpostSample*)sample in:(NSMutableArray<DTXSignpostSampleWithChildrenProxy*>*)rv
{
	if(rv.count == 0)
	{
		[rv addObject:[[DTXSignpostSampleWithChildrenProxy alloc] _initWithSignpostSample:sample]];
		return;
	}
	
	BOOL didAdd = NO;
	for(DTXSignpostSampleWithChildrenProxy* proxy in rv)
	{
		didAdd = [proxy _addChildSampleIfPossible:sample];
		
		if(didAdd)
		{
			break;
		}
	}
	
	if(didAdd == NO)
	{
		[rv addObject:[[DTXSignpostSampleWithChildrenProxy alloc] _initWithSignpostSample:sample]];
	}
}

+ (NSArray<DTXSignpostSampleWithChildrenProxy*>*)sortedSamplesFromFetchedResultsController:(NSFetchedResultsController*)frc
{
	NSMutableArray* rv = [NSMutableArray new];
	
	for(DTXSignpostSample* sample in frc.fetchedObjects)
	{
		[self _insertSample:sample in:rv];
	}
	
	return rv;
}

- (instancetype)_initWithSignpostSample:(DTXSignpostSample*)sample
{
	self = [super init];
	
	if(self)
	{
		_sample = sample;
		_timestamp = sample.timestamp;
		_endTimestamp = sample.defactoEndTimestamp;
		_children = [NSMutableArray new];
	}
	
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p category: %@ name: %@ samplesCount: %@>", self.className, self, _sample.category, _sample.name, @(_children.count)];
}

- (BOOL)_addChildSampleIfPossible:(DTXSignpostSample*)childSample
{
	NSDate* sampleTimestamp = childSample.timestamp;
	NSDate* sampleEndTimestamp = childSample.defactoEndTimestamp;
	
	//We make an assumption that samples are sorted and next always starts after the current.
	if([sampleTimestamp compare:_endTimestamp] == NSOrderedDescending || [sampleEndTimestamp compare:_endTimestamp] == NSOrderedDescending)
	{
		return NO;
	}
	
	[DTXSignpostSampleWithChildrenProxy _insertSample:childSample in:_children];
	return YES;
}

- (BOOL)isExpandable
{
	return _children.count > 0;
}

- (BOOL)wantsStandardGroupDisplay
{
	return YES;
}

- (NSUInteger)samplesCount
{
	return _children.count;
}

- (id)sampleAtIndex:(NSUInteger)index
{
	return _children[index];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return _sample;
}

@end
