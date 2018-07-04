//
//  DTXSignpostCategoryProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSampleAggregatorProxy.h"
#import "DTXSignpostProtocol.h"

@interface DTXSignpostCategoryProxy : DTXSampleAggregatorProxy <DTXSignpost>

@property (nonatomic, strong, readonly) NSString* category;

- (instancetype)initWithCategory:(NSString*)category recording:(DTXRecording*)recording outlineView:(NSOutlineView*)outlineView;

@end
