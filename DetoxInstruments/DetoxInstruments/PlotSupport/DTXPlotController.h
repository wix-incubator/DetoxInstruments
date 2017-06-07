//
//  DTXPlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import Cocoa;
#import <CorePlot/CorePlot.h>

@protocol DTXPlotController;

@protocol DTXPlotControllerDelegate <NSObject>

- (void)plotController:(id<DTXPlotController>)pc didChangeToPlotRange:(CPTPlotRange *)plotRange;

@end

@protocol DTXPlotController <NSObject>

@property (nonatomic, weak) id<DTXPlotControllerDelegate> delegate;

@property (nonatomic, strong, readonly) NSString* displayName;
@property (nonatomic, strong, readonly) NSImage* displayIcon;

@property (nonatomic, assign, readonly) CGFloat requiredHeight;

- (void)setUpWithView:(NSView*)view;
- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets;
- (void)setPlotRange:(CPTPlotRange *)plotRange;

@end
