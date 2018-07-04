//
//  DTXSampleAggregatorProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSampleContainerProxy.h"
#import "DTXRecording+Additions.h"

@interface DTXSampleAggregatorProxy : DTXSampleContainerProxy

@property (nonatomic, strong, readonly) NSString* keyPath;
@property (nonatomic, strong, readonly) DTXRecording* recording;
@property (nonatomic, strong, readonly) Class sampleClass;
@property (nonatomic, strong, readonly) NSPredicate* predicateForAggregator;

- (instancetype)initWithKeyPath:(NSString*)keyPath isRoot:(BOOL)root recording:(DTXRecording*)recording outlineView:(NSOutlineView*)outlineView;

@end
