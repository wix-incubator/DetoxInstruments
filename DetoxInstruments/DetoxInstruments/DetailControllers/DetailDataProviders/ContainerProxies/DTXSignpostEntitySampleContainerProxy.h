//
//  DTXSignpostEntitySampleContainerProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/25/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXEntitySampleContainerProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXSignpostEntitySampleContainerProxy : DTXEntitySampleContainerProxy

- (instancetype)initWithOutlineView:(NSOutlineView *)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext sampleClass:(Class)sampleClass;

@end

NS_ASSUME_NONNULL_END
