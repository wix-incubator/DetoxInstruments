//
//  DTXPlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import Cocoa;
#import <CorePlot/CorePlot.h>
#import "DTXDocument.h"

@class DTXDetailController;

@protocol DTXPlotController;

@protocol DTXPlotControllerDelegate <NSObject>

- (void)plotController:(id<DTXPlotController>)pc didChangeToPlotRange:(CPTPlotRange *)plotRange;
- (void)plotControllerUserDidClickInPlotBounds:(id<DTXPlotController>)pc;
- (void)requiredHeightChangedForPlotController:(id<DTXPlotController>)pc;
- (void)plotController:(id<DTXPlotController>)pc didHighlightAtSampleTime:(NSTimeInterval)sampleTime;

@end

@protocol DTXPlotControllerSampleClickHandlingDelegate <NSObject>

- (void)plotController:(id<DTXPlotController>)pc didClickOnSample:(DTXSample *)sample;

@end

@protocol DTXPlotController <NSObject>

@property (nonatomic, strong, readonly) DTXDocument* document;
@property (nonatomic, weak) id<DTXPlotControllerDelegate> delegate;

@property (nonatomic, strong, readonly) NSString* displayName;
@property (nonatomic, strong, readonly) NSImage* displayIcon;
@property (nonatomic, strong, readonly) NSImage* smallDisplayIcon;
@property (nonatomic, strong, readonly) NSImage* secondaryIcon;
@property (nonatomic, strong, readonly) NSString* toolTip;
@property (nonatomic, strong, readonly) NSFont* titleFont;
@property (nonatomic, strong, readonly) NSArray<NSString*>* legendTitles;
@property (nonatomic, strong, readonly) NSArray<NSColor*>* legendColors;

@property (nonatomic, assign, readonly) CGFloat requiredHeight;

@property (nonatomic, copy, readonly) NSArray<DTXDetailController*>* dataProviderControllers;

- (instancetype)initWithDocument:(DTXDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)setUpWithView:(NSView*)view;
- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets;

- (void)setGlobalPlotRange:(CPTPlotRange*)globalPlotRange;
- (void)setPlotRange:(CPTPlotRange*)plotRange;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomToFitAllData;

@optional

@property (nonatomic, weak) id<DTXPlotControllerSampleClickHandlingDelegate> sampleClickDelegate;

- (void)highlightSample:(id)sample;
- (void)shadowHighlightAtSampleTime:(NSTimeInterval)sampleTime;
- (void)highlightRange:(CPTPlotRange*)range;
- (void)removeHighlight;

@property (nonatomic, assign, readonly) BOOL canReceiveFocus;

@end
