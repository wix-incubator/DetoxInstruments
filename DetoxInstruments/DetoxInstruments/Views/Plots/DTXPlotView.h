//
//  DTXPlotView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXPlotRange.h"

@interface DTXPlotViewAnnotation : NSObject

@property (nonatomic) double position;
@property (nonatomic, strong) NSColor* color;
@property (nonatomic) double opacity;
@property (nonatomic) double priority;

@end

@interface DTXPlotViewLineAnnotation : DTXPlotViewAnnotation

@end

@interface DTXPlotViewRangeAnnotation : DTXPlotViewAnnotation

@property (nonatomic) double end;

@end

@interface DTXPlotViewTextAnnotation : DTXPlotViewAnnotation

@property (nonatomic) BOOL showsValue;
@property (nonatomic) double value;
@property (nonatomic, strong) NSColor* valueColor;

@property (nonatomic) BOOL showsText;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSColor* textColor;
@property (nonatomic, strong) NSColor* textBackgroundColor;

@property (nonatomic) BOOL showsAdditionalText;
@property (nonatomic, strong) NSString* additionalText;
@property (nonatomic, strong) NSColor* additionalTextColor;

@end

@class DTXPlotView;

@protocol DTXPlotViewDelegate <NSObject>

- (void)plotViewDidChangePlotRange:(DTXPlotView*)plotView;

@optional

- (void)plotViewIntrinsicContentSizeDidChange:(DTXPlotView*)plotView;

@end

@protocol DTXPlotViewDataSource <NSObject>

- (NSUInteger)numberOfSamplesInPlotView:(DTXPlotView*)plotView;

@end

@interface DTXPlotView : NSView

@property (nonatomic, weak) IBOutlet id<DTXPlotViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet id<DTXPlotViewDataSource> dataSource;

@property (nonatomic) NSEdgeInsets insets;
@property (nonatomic) CGFloat minimumHeight;
@property (readonly) NSSize intrinsicContentSize;

@property (nonatomic, strong) NSArray<DTXPlotViewAnnotation*>* annotations;
@property (nonatomic) BOOL fadesOnRangeAnnotation;

@property (nonatomic, copy) DTXPlotRange* plotRange;
@property (nonatomic, copy) DTXPlotRange* globalPlotRange;
@property (nonatomic, copy) DTXPlotRange* dataLimitRange;
- (void)scalePlotRange:(double)scale atPoint:(CGPoint)point;

- (void)reloadData;
@property (nonatomic, readonly, getter=isDataLoaded) BOOL dataLoaded;

@property (getter=isFlipped, readwrite) BOOL flipped;

@property (nonatomic) NSUInteger plotIndex;

- (NSPoint)convertPointFromWindow:(NSPoint)point;

@end
