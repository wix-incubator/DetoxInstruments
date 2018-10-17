//
//  DTXScrollView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXScrollView.h"

@interface NSObject ()

- (void)_setIsHorizontal:(BOOL)arg1;

@end

@interface DTXScroller : NSScroller @end
@implementation DTXScroller

+ (BOOL)isCompatibleWithOverlayScrollers
{
	return self == [DTXScroller class];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

	NSBezierPath* line = [NSBezierPath bezierPath];

	[line moveToPoint:NSMakePoint(0, 0)];
	[line lineToPoint:NSMakePoint(0, self.bounds.size.height)];

	line.lineWidth = 1.0;
	[NSColor.gridColor set];
	[line stroke];
}

@end

@interface NSScrollView ()

@end

@implementation DTXScrollView
{
	BOOL _requiresCustomHorizontalScrollerManagement;
	CGFloat _knobProportion;
	CGFloat _knobValue;
	
	DTXScroller* _horizontalScroller;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	_requiresCustomHorizontalScrollerManagement = YES;
	
	_horizontalScroller = [DTXScroller new];
	_horizontalScroller.enabled = YES;
	[_horizontalScroller _setIsHorizontal:YES];
	_horizontalScroller.scrollerStyle = [NSScroller preferredScrollerStyle];
	
	self.horizontalScroller.alphaValue = 0.0;
	
	[self addSubview:_horizontalScroller];
}

- (NSScroller *)customHorizontalScroller
{
	return _horizontalScroller;
}

- (void)setHorizontalScrollerKnobProportion:(CGFloat)proportion value:(CGFloat)value
{
	_requiresCustomHorizontalScrollerManagement = YES;
	
	_knobProportion = proportion;
	_knobValue = value;
	
	[self _resetHorizontalScrollerKnob];
}

- (void)reflectScrolledClipView:(NSClipView *)cView
{
	[super reflectScrolledClipView:cView];
	
	if(_requiresCustomHorizontalScrollerManagement)
	{
		[self _resetHorizontalScrollerKnob];
	}
}

- (void)_resetHorizontalScrollerKnob
{
	_horizontalScroller.enabled = YES;
	[_horizontalScroller setKnobProportion:_knobProportion];
	[_horizontalScroller setDoubleValue:_knobValue];
	
	self.horizontalScroller.alphaValue = 0.0;
	
//	[[self valueForKey:@"scrollerImpPair"] _updateOverlayScrollersStateWithReason:@"user update horizontal scroller" forcingVisibilityForHorizontalKnob:1 verticalKnob:1];
}

- (void)tile
{
	[super tile];
	
	_horizontalScroller.frame = self.horizontalScroller.frame;
}

@end
