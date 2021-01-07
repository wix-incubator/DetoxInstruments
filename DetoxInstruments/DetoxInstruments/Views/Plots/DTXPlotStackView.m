//
//  DTXPlotStackView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/31/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXPlotStackView.h"
#import "DTXScatterPlotView-Private.h"

@interface DTXPlotStackView () <DTXPlotHeightSynchronization>

@end

@implementation DTXPlotStackView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if(self)
	{
		[self _commonInitPlotStackView];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if(self)
	{
		[self _commonInitPlotStackView];
	}
	return self;
}

- (void)_commonInitPlotStackView
{
	self.shouldSynchronizePlotHeights = YES;
}

@synthesize maximumPlotHeight=_maximumPlotHeight;

- (void)_applyHeightSynchronization:(NSView*)view
{
	if([view isKindOfClass:DTXScatterPlotView.class])
	{
		DTXScatterPlotView* scatterPlotView = (id)view;
		scatterPlotView.heightSynchronizer = self.shouldSynchronizePlotHeights ? self : nil;
	}
}

- (void)insertArrangedSubview:(NSView *)view atIndex:(NSInteger)index
{
	[super insertArrangedSubview:view atIndex:index];
	
	[self _applyHeightSynchronization:view];
}

- (void)setShouldSynchronizePlotHeights:(BOOL)shouldSynchronizePlotHeights
{
	_shouldSynchronizePlotHeights = shouldSynchronizePlotHeights;
	
	[self.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[self _applyHeightSynchronization:obj];
	}];
}

- (void)removeArrangedSubview:(NSView *)view
{
	[super removeArrangedSubview:view];
	
	if([view isKindOfClass:DTXScatterPlotView.class])
	{
		DTXScatterPlotView* scatterPlotView = (id)view;
		scatterPlotView.heightSynchronizer = nil;
	}
}

- (NSView *)hitTest:(NSPoint)point
{
	NSView* rv = [super hitTest:point];
	
	if(rv == self)
	{
		return self.arrangedSubviews.firstObject;
	}
	
	return rv;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
//	CGContextSetLineWidth(ctx, 1.0);
//	CGContextSetStrokeColorWithColor(ctx, NSColor.gridColor.CGColor);
//	
//	[self.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//		if(idx == self.arrangedSubviews.count - 1)
//		{
//			return;
//		}
//		
//		CGContextMoveToPoint(ctx, 0, obj.frame.origin.y);
//		CGContextAddLineToPoint(ctx, self.bounds.size.width, obj.frame.origin.y);
//	}];
//	
//	CGContextStrokePath(ctx);
//}

@end
