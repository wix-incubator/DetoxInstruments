//
//  DTXActivitySampleContainerProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/25/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXActivitySampleContainerProxy.h"

@implementation DTXActivitySampleContainerProxy
{
	NSSet<NSString*>* _enabledCategories;
}

- (instancetype)initWithOutlineView:(NSOutlineView *)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext sampleClass:(Class)sampleClass enabledCategories:(NSSet<NSString*>*)enabledCategories
{
	self = [super initWithOutlineView:outlineView managedObjectContext:managedObjectContext sampleClass:sampleClass];
	
	if(self)
	{
		_enabledCategories = enabledCategories;
		
		if(_enabledCategories)
		{
			self.fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.fetchRequest.predicate, [NSPredicate predicateWithFormat:@"category IN %@", _enabledCategories]]];
		}
	}
	
	return self;
}

@end
