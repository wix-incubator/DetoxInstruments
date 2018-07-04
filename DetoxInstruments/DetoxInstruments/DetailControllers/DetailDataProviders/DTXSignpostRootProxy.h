//
//  DTXSignpostRootProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/1/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSampleAggregatorProxy.h"

@interface DTXSignpostRootProxy : DTXSampleAggregatorProxy

- (instancetype)initWithRecording:(DTXRecording*)recording outlineView:(NSOutlineView*)outlineView;

@end
