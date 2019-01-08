//
//  DTXSampleGroupProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#if 0

#import <Foundation/Foundation.h>
#import "DTXSampleContainerProxy.h"
#import "DTXInstrumentsModel.h"
#import "DTXInspectorDataProvider.h"

@interface DTXSampleGroupProxy : DTXSampleContainerProxy

@property (nonatomic, strong, readonly) DTXSampleGroup* sampleGroup;
@property (nonatomic, strong, readonly) NSArray<NSNumber*>* sampleTypes;
@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly) NSDate* timestamp;
@property (nonatomic, strong, readonly) NSDate* closeTimestamp;

- (instancetype)initWithOutlineView:(NSOutlineView*)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext sampleTypes:(NSArray<NSNumber*>*)sampleTypes;

@end

#endif
