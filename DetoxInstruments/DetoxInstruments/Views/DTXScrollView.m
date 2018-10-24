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
- (void)setOverlayScrollerTrackAlpha:(double)arg1;
- (void)setOverlayScrollerKnobAlpha:(double)arg1;
- (double)overlayScrollerKnobAlpha;

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

- (void)setScrollerStyle:(NSScrollerStyle)scrollerStyle
{
	[super setScrollerStyle:scrollerStyle];
	
	[self _resetStyles];
	[self _animateKnobIfNeeded];
}

- (void)setKnobProportion:(CGFloat)proportion
{
	float oldProportion = self.knobProportion;
	
	[super setKnobProportion:proportion];
	
	[self _resetStyles];
	
	if(oldProportion != self.knobProportion)
	{
		[self _animateKnobIfNeeded];
	}
}

- (void)setDoubleValue:(double)doubleValue
{
	double oldDoubleValue = self.doubleValue;
	
	[super setDoubleValue:doubleValue];
	
	[self _resetStyles];
	
	if(oldDoubleValue != self.doubleValue)
	{
		[self _animateKnobIfNeeded];
	}
}

- (void)_resetStyles
{
	self.enabled = YES;

	if(self.scrollerStyle == NSScrollerStyleOverlay)
	{
		[self setOverlayScrollerTrackAlpha:0.0];
	}
	else
	{
		[self setOverlayScrollerTrackAlpha:1.0];
	}
}

- (void)_fadeOut
{
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.2;
		context.allowsImplicitAnimation = YES;
		[self.animator setOverlayScrollerKnobAlpha:0.0];
	} completionHandler:^{
		
	}];
}

- (void)_animateKnobIfNeeded
{
	if(self.scrollerStyle == NSScrollerStyleLegacy)
	{
		[self setOverlayScrollerKnobAlpha:1.0];
		
		return;
	}
	
	if(self.knobProportion == 1.0)
	{
		[self _fadeOut];
	}
	else
	{
		[self setOverlayScrollerKnobAlpha:1.0];
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		
		[self performSelector:@selector(_fadeOut) withObject:nil afterDelay:1.0];
	}
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

- (void)_scrollerStyleDidChange_DTX
{
	_horizontalScroller.scrollerStyle = [NSScroller preferredScrollerStyle];
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
	[_horizontalScroller setOverlayScrollerTrackAlpha:0.0];
	_horizontalScroller.scrollerStyle = [NSScroller preferredScrollerStyle];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_scrollerStyleDidChange_DTX) name:NSPreferredScrollerStyleDidChangeNotification object:nil];
	
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
	[_horizontalScroller setKnobProportion:_knobProportion];
	[_horizontalScroller setDoubleValue:_knobValue];
	
	self.horizontalScroller.alphaValue = 0.0;
}

- (void)reflectScrolledClipView:(NSClipView *)cView
{
	[super reflectScrolledClipView:cView];
	
	if(_requiresCustomHorizontalScrollerManagement)
	{
		self.horizontalScroller.alphaValue = 0.0;
	}
}

- (void)tile
{
	[super tile];
	
	_horizontalScroller.frame = self.horizontalScroller.frame;
}

@end
