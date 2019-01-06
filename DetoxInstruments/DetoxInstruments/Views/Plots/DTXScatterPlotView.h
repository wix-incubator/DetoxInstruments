//
//  DTXScatterPlotView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/30/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotView.h"

@interface DTXScatterPlotViewPoint : NSObject

@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;

@end

@class DTXScatterPlotView;

@protocol DTXScatterPlotViewDelegate <DTXPlotViewDelegate>

- (void)plotView:(DTXScatterPlotView*)plotView didClickPointAtIndex:(NSUInteger)idx clickPositionInPlot:(double)position valueAtClickPosition:(double)value;

@end

@protocol DTXScatterPlotViewDataSource <DTXPlotViewDataSource>

- (DTXScatterPlotViewPoint*)plotView:(DTXScatterPlotView*)plotView pointAtIndex:(NSUInteger)idx;

@end

@interface DTXScatterPlotView : DTXPlotView

@property (nonatomic, weak) id<DTXScatterPlotViewDelegate> delegate;
@property (nonatomic, weak) id<DTXScatterPlotViewDataSource> dataSource;

@property (nonatomic) double lineWidth;
@property (nonatomic, strong) NSColor* lineColor;
@property (nonatomic, strong) NSColor* fillColor1;
@property (nonatomic, strong) NSColor* fillColor2;

@property (nonatomic) double minimumValueForPlotHeight;
@property (nonatomic) double plotHeightMultiplier;

@property (nonatomic, getter=isStepped) BOOL stepped;

- (void)reloadPointAtIndex:(NSUInteger)index;
- (void)addNumberOfPoints:(NSUInteger)numberOfPoints;

- (NSUInteger)indexOfPointAtViewPosition:(CGFloat)viewPosition positionInPlot:(out double *)position valueAtPlotPosition:(out double *)value;
- (double)valueAtPlotPosition:(double)position;
- (double)valueOfPointIndex:(NSUInteger)idx;

@end
