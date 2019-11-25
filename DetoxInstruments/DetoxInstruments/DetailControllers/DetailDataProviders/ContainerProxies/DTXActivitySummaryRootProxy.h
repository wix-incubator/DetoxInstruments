//
//  DTXActivitySummaryRootProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/1/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSampleAggregatorProxy.h"

@interface DTXActivitySummaryRootProxy : DTXSampleAggregatorProxy

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView;

@end
