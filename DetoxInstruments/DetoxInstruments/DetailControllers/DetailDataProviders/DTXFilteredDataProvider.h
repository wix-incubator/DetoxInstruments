//
//  DTXFilteredDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRecordingDocument.h"
#import "DTXInstrumentsModel.h"

@interface DTXFilteredDataProvider : NSObject <NSOutlineViewDataSource>

- (instancetype)initWithDocument:(DTXRecordingDocument*)document managedOutlineView:(NSOutlineView*)managedOutlineView sampleClass:(Class)sampleClass filteredAttributes:(NSArray<NSString*>*)filteredAttributes;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) DTXRecordingDocument* document;
@property (nonatomic, weak, readonly) NSOutlineView* managedOutlineView;
@property (nonatomic, strong, readonly) Class sampleClass;
@property (nonatomic, strong, readonly) NSArray<NSString*>* filteredAttributes;

- (void)filterSamplesWithPredicate:(NSPredicate*)predicate;

@end
