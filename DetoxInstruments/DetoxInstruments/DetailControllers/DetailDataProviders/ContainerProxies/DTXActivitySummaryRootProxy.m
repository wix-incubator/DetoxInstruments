//
//  DTXActivitySummaryRootProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/1/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXActivitySummaryRootProxy.h"
#import "DTXActivitySample+UIExtensions.h"
#import "DTXActivityCategoryProxy.h"

@implementation DTXActivitySummaryRootProxy
{
	NSSet<NSString*>* _enabledCategories;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView enabledCategories:(NSSet<NSString*>*)enabledCategories
{
	self = [super initWithKeyPath:@"category" outlineView:outlineView managedObjectContext:managedObjectContext isRoot:YES];
	
	if(self)
	{
		_enabledCategories = enabledCategories;
	}
	
	return self;
}

- (Class)sampleClass
{
	return DTXActivitySample.class;
}

- (id)objectForSample:(id)sample
{
	return [[DTXActivityCategoryProxy alloc] initWithCategory:sample managedObjectContext:self.managedObjectContext outlineView:self.outlineView];
}

- (NSArray<NSSortDescriptor *> *)sortDescriptorsForAggregator
{
	return @[[NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES]];
}

- (NSPredicate *)predicateForAggregator
{
	if(_enabledCategories)
	{
		return [NSPredicate predicateWithFormat:@"category IN %@", _enabledCategories];
	}
	
	return [super predicateForAggregator];
}

@end
