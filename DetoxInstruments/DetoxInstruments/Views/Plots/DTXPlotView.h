//
//  DTXPlotView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CPTMutablePlotRange.h>

@interface DTXPlotViewAnnotation : NSObject

@property (nonatomic) double position;
@property (nonatomic, strong) NSColor* color;
@property (nonatomic) double opacity;
@property (nonatomic) double priority;

@end

@interface DTXPlotViewLineAnnotation : DTXPlotViewAnnotation

@property (nonatomic) double value;

@property (nonatomic) bool drawsValue;
@property (nonatomic, strong) NSColor* valueColor;

@end

@interface DTXPlotViewRangeAnnotation : DTXPlotViewAnnotation

@property (nonatomic) double end;

@end

@interface DTXPlotViewTextAnnotation : DTXPlotViewAnnotation

@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSColor* valueColor;
@end

@class DTXPlotView;

@protocol DTXPlotViewDelegate <NSObject>

- (void)plotViewDidChangePlotRange:(DTXPlotView*)plotView;

@end

@protocol DTXPlotViewDataSource <NSObject>

- (NSUInteger)numberOfSamplesInPlotView:(DTXPlotView*)plotView;

@end

@interface DTXPlotView : NSView

@property (nonatomic, weak) id<DTXPlotViewDelegate> delegate;
@property (nonatomic, weak) id<DTXPlotViewDataSource> dataSource;

@property (nonatomic) NSEdgeInsets insets;
@property (nonatomic) CGFloat minimumHeight;

@property (nonatomic, strong) NSArray<DTXPlotViewAnnotation*>* annotations;

@property (nonatomic, copy) CPTPlotRange *plotRange;
@property (nonatomic, copy) CPTPlotRange *globalPlotRange;
- (void)scalePlotRange:(double)scale atPoint:(CGPoint)point;

- (void)reloadData;
@property (nonatomic) BOOL isDataLoaded;

@property (getter=isFlipped, readwrite) BOOL flipped;

@property (nonatomic) NSUInteger plotIndex;

@end
