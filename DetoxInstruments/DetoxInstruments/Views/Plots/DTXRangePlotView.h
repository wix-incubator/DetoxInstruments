//
//  DTXRangePlotView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotView.h"

@interface DTXRange : NSObject

@property (nonatomic) CGFloat start;
@property (nonatomic) CGFloat end;
@property (nonatomic) CGFloat height;
@property (nonatomic, strong) NSColor* color;

@end

@class DTXRangePlotView;

@protocol DTXRangePlotViewDelegate <DTXPlotViewDelegate>

- (void)plotView:(DTXRangePlotView*)plotView didClickRangeAtIndex:(NSUInteger)idx;

@end

@protocol DTXRangePlotViewDataSource <DTXPlotViewDataSource>

- (DTXRange*)plotView:(DTXRangePlotView*)plotView rangeAtIndex:(NSUInteger)idx;

@end

@interface DTXRangePlotView : DTXPlotView

@property (nonatomic, weak) id<DTXRangePlotViewDelegate> delegate;
@property (nonatomic, weak) id<DTXRangePlotViewDataSource> dataSource;

@property (nonatomic) double lineHeight;
@property (nonatomic) double lineSpacing;

- (void)reloadRangeAtIndex:(NSUInteger)idx;

@end
