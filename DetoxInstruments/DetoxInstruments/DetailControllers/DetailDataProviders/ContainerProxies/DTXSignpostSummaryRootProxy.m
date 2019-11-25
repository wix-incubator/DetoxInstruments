//
//  DTXSignpostSummaryRootProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/1/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSignpostSummaryRootProxy.h"
#import "DTXSignpostCategoryProxy.h"
#import "DTXSignpostSample+UIExtensions.h"

@implementation DTXSignpostSummaryRootProxy

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView
{
	self = [super initWithKeyPath:@"category" outlineView:outlineView managedObjectContext:managedObjectContext isRoot:YES];
	
	if(self)
	{
	}
	
	return self;
}

- (NSPredicate *)predicateForAggregator
{
	return [NSPredicate predicateWithFormat:@"sampleType == %@", @(DTXSampleTypeSignpost)];
}

- (Class)sampleClass
{
	return DTXSignpostSample.class;
}

- (id)objectForSample:(id)sample
{
	return [[DTXSignpostCategoryProxy alloc] initWithCategory:sample managedObjectContext:self.managedObjectContext outlineView:self.outlineView];
}

@end
