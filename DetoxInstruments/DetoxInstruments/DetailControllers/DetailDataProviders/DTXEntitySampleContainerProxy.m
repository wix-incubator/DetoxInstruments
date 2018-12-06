//
//  DTXEntitySampleContainerProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/6/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXEntitySampleContainerProxy.h"

@implementation DTXEntitySampleContainerProxy

@synthesize fetchRequest=_fetchRequest;

- (instancetype)initWithOutlineView:(NSOutlineView *)outlineView sampleClass:(Class)sampleClass managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	self = [super initWithOutlineView:outlineView isRoot:YES managedObjectContext:managedObjectContext];
	
	if(self)
	{
		_sampleClass = sampleClass;
		_fetchRequest = [_sampleClass fetchRequest];
		_fetchRequest.predicate = [NSPredicate predicateWithFormat:@"hidden == NO"];
		
		NSArray* sortDescriptors = outlineView.sortDescriptors;
		if(sortDescriptors.count == 0)
		{
			sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		}
		
		_fetchRequest.sortDescriptors = sortDescriptors;
		
		outlineView.sortDescriptors = _fetchRequest.sortDescriptors;
	}
	
	return self;
}

- (BOOL)supportsSorting
{
	return YES;
}

- (NSFetchRequest *)fetchRequest
{
	return _fetchRequest;
}

@end
