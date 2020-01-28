//
//  DTXSignpostEntitySampleContainerProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/25/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXSignpostEntitySampleContainerProxy.h"

@implementation DTXSignpostEntitySampleContainerProxy

- (instancetype)initWithOutlineView:(NSOutlineView *)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext sampleClass:(Class)sampleClass
{
	self = [super initWithOutlineView:outlineView managedObjectContext:managedObjectContext sampleClass:sampleClass predicate:nil];
	
	if(self)
	{
		self.fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.fetchRequest.predicate, [NSPredicate predicateWithFormat:@"sampleType == %@", @(DTXSampleTypeSignpost)]]];
	}
	
	return self;
}

@end
