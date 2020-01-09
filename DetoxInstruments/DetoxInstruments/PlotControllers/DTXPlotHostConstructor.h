//
//  DTXPlotHostConstructor.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXLayerView.h"
#if __has_include(<CorePlot/CorePlot.h>)
#import "DTXGraphHostingView.h"
#endif
#import "DTXPlotStackView.h"

CGFloat DTXCurrentTouchBarHeight(void);

@interface DTXPlotHostConstructor : NSObject

@property (nonatomic, strong, readonly) DTXLayerView* wrapperView;
@property (nonatomic, readonly) BOOL isForTouchBar;

- (instancetype)initForTouchBar:(BOOL)isForTouchBar;

- (void)setUpWithView:(NSView *)view;
- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets;
- (void)didFinishViewSetup;

- (BOOL)usesInternalPlots;

#pragma mark Internal Plot Support

@property (nonatomic, strong, readonly) DTXPlotStackView* plotStackView;
- (void)reloadPlotViews;
- (void)setupPlotViews;

@property (nonatomic, readonly) CGFloat requiredHeight;

#if __has_include(<CorePlot/CorePlot.h>)
#pragma mark Core Plot Support

@property (nonatomic, strong, readonly) __kindof DTXGraphHostingView* hostingView;
@property (nonatomic, strong, readonly) CPTGraph* graph;
- (void)setupPlotsForGraph;
#endif

@end
