//
//  DTXEntitySampleContainerProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/6/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSampleContainerProxy.h"

@interface DTXEntitySampleContainerProxy : DTXSampleContainerProxy

@property (nonatomic, strong, readonly) Class sampleClass;

- (instancetype)initWithOutlineView:(NSOutlineView *)outlineView sampleClass:(Class)sampleClass managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
