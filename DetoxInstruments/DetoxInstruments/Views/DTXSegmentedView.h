//
//  DTXSegmentedView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 15/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DTXSegmentedView;

@protocol DTXSegmentedViewDelegate

- (void)segmentedView:(DTXSegmentedView*)segmentedView didSelectSegmentAtIndex:(NSInteger)index;

@end


@interface DTXSegmentedView : NSSegmentedControl

@property (nonatomic, weak) id<DTXSegmentedViewDelegate> delegate;

@end
