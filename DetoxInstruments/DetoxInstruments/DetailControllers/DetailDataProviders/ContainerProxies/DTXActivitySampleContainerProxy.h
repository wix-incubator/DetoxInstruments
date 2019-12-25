//
//  DTXActivitySampleContainerProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/25/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXEntitySampleContainerProxy.h"

@interface DTXActivitySampleContainerProxy : DTXEntitySampleContainerProxy

- (instancetype)initWithOutlineView:(NSOutlineView *)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext sampleClass:(Class)sampleClass enabledCategories:(NSSet<NSString*>*)enabledCategories;

@end
