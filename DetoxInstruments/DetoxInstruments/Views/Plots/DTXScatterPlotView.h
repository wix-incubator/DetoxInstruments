//
//  DTXScatterPlotView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/30/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
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

- (BOOL)hasAdditionalPointsForPlotView:(DTXScatterPlotView*)plotView;

- (DTXScatterPlotViewPoint*)plotView:(DTXScatterPlotView*)plotView pointAtIndex:(NSUInteger)idx;
//Only the Y component of the additional point is used.
- (DTXScatterPlotViewPoint*)plotView:(DTXScatterPlotView*)plotView additionalPointAtIndex:(NSUInteger)idx;

@end

@interface DTXScatterPlotView : DTXPlotView

@property (nonatomic, weak) id<DTXScatterPlotViewDelegate> delegate;
@property (nonatomic, weak) id<DTXScatterPlotViewDataSource> dataSource;

@property (nonatomic) double lineWidth;
@property (nonatomic, strong) NSColor* lineColor;
@property (nonatomic, strong) NSColor* fillColor1;
@property (nonatomic, strong) NSColor* fillColor2;

@property (nonatomic, strong) NSColor* additionalLineColor;
@property (nonatomic) double additionalFillStartValue;
@property (nonatomic) double additionalFillLimitValue;
@property (nonatomic, strong) NSColor* additionalFillColor1;
@property (nonatomic, strong) NSColor* additionalFillColor2;

@property (nonatomic) double minimumValueForPlotHeight;
@property (nonatomic) double plotHeightMultiplier;

@property (nonatomic, getter=isStepped) BOOL stepped;

@property (nonatomic, readonly) BOOL hasAdditionalPoints;

- (void)reloadPointAtIndex:(NSUInteger)index;
- (void)addNumberOfPoints:(NSUInteger)numberOfPoints;

- (NSUInteger)indexOfPointAtViewPosition:(CGFloat)viewPosition positionInPlot:(out double *)position valueAtPlotPosition:(out double *)value;

- (double)valueAtPlotPosition:(double)position exact:(BOOL)exact;
- (double)valueOfPointIndex:(NSUInteger)idx;

- (double)additionalValueAtPlotPosition:(double)position exact:(BOOL)exact;
- (double)additionalValueOfPointIndex:(NSUInteger)idx;

@end
