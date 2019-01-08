//
//  DTXEntitySampleContainerProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/6/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXEntitySampleContainerProxy.h"

@implementation DTXEntitySampleContainerProxy

@synthesize fetchRequest=_fetchRequest;

- (instancetype)initWithOutlineView:(NSOutlineView *)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext sampleClass:(Class)sampleClass
{
	self = [super initWithOutlineView:outlineView managedObjectContext:managedObjectContext isRoot:YES];
	
	if(self)
	{
		NSParameterAssert(sampleClass != nil);
		
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

- (NSFetchRequest *)fetchRequest
{
	NSParameterAssert(_fetchRequest != nil);
	
	return _fetchRequest;
}

@end
