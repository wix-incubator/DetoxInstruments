//
//  DTXRangePlotView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXPlotView.h"

extern const CGFloat DTXRangePlotViewDefaultLineWidth;
extern const CGFloat DTXRangePlotViewDefaultLineSpacing;

@interface DTXRangePlotViewRange : NSObject

@property (nonatomic) CGFloat start;
@property (nonatomic) CGFloat end;
@property (nonatomic) CGFloat height;
@property (nonatomic, strong) NSColor* color;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSColor* titleColor;

@end

@class DTXRangePlotView;

@protocol DTXRangePlotViewDelegate <DTXPlotViewDelegate>

- (void)plotView:(DTXRangePlotView*)plotView didClickRangeAtIndex:(NSUInteger)idx;

@end

@protocol DTXRangePlotViewDataSource <DTXPlotViewDataSource>

- (DTXRangePlotViewRange*)plotView:(DTXRangePlotView*)plotView rangeAtIndex:(NSUInteger)idx;

@end

@interface DTXRangePlotView : DTXPlotView

@property (nonatomic, weak) id<DTXRangePlotViewDelegate> delegate;
@property (nonatomic, weak) id<DTXRangePlotViewDataSource> dataSource;

@property (nonatomic) double lineWidth;
@property (nonatomic) double lineSpacing;

@property (nonatomic, getter = drawsTitles) BOOL drawTitles;

- (void)reloadRangeAtIndex:(NSUInteger)idx;

@end
