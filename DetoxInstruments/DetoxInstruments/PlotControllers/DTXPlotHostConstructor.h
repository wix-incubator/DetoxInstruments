//
//  DTXPlotHostConstructor.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXLayerView.h"
#import "DTXGraphHostingView.h"

@interface DTXPlotHostConstructor : NSObject

@property (nonatomic, strong, readonly) DTXLayerView* wrapperView;
@property (nonatomic, strong, readonly) DTXGraphHostingView* hostingView;
@property (nonatomic, strong, readonly) CPTGraph* graph;

- (void)setUpWithView:(NSView *)view;
- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets;
- (void)setupPlotsForGraph;
- (void)didFinishViewSetup;

@end
