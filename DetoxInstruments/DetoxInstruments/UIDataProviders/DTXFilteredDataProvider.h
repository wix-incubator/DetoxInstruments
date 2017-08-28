//
//  DTXFilteredDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXDocument.h"
#import "DTXInstrumentsModel.h"

@interface DTXFilteredDataProvider : NSObject <NSOutlineViewDataSource>

- (instancetype)initWithDocument:(DTXDocument*)document managedOutlineView:(NSOutlineView*)managedOutlineView sampleTypes:(NSArray<NSNumber* /* DTXSampleType */>*)sampleTypes filteredAttributes:(NSArray<NSString*>*)filteredAttributes;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) DTXDocument* document;
@property (nonatomic, weak, readonly) NSOutlineView* managedOutlineView;
@property (nonatomic, strong, readonly) NSArray<NSNumber* /* DTXSampleType */>* sampleTypes;
@property (nonatomic, strong, readonly) NSArray<NSString*>* filteredAttributes;

- (void)filterSamplesWithFilter:(NSString*)filter;

@end
