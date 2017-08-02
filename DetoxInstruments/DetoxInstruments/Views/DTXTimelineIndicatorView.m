//
//  DTXTimelineMouseView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXTimelineIndicatorView.h"

@interface _DTXDashedLineLayer : CALayer
@end

@implementation _DTXDashedLineLayer

- (void)drawInContext:(CGContextRef)context
{
	CGContextSetLineWidth(context, 1.5 / self.contentsScale);
	CGContextSetLineDash(context, 5.0, (CGFloat[]){5.,5.}, 2);
	
	CGContextSetStrokeColorWithColor(context, NSColor.blackColor.CGColor);
	CGContextMoveToPoint(context, 0, 0);    // This sets up the start point
	CGContextAddLineToPoint(context, 0, self.bounds.size.height);
	CGContextStrokePath(context);
}

@end

@interface DTXTimelineIndicatorView () <CALayerDelegate> @end
@implementation DTXTimelineIndicatorView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		self.wantsLayer = YES;
		self.acceptsTouchEvents = NO;
	}
	
	return self;
}

-(void)viewDidChangeBackingProperties
{
	if (self.window)
	{
		self.layer.contentsScale = self.window.backingScaleFactor;
	}
	else
	{
		self.layer.contentsScale = 1.0;
	}
	
	[self.layer setNeedsDisplay];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (void)layout
{
	[super layout];
	
	[self.layer setNeedsDisplay];
}

- (void)viewDidMoveToWindow
{
	[self viewDidChangeBackingProperties];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	return nil;
}

- (void)setIndicatorOffset:(CGFloat)indicatorOffset
{
	_indicatorOffset = indicatorOffset;
	
	[self.layer setNeedsDisplay];
}

- (void)setDisplaysIndicator:(BOOL)displaysIndicator
{
	_displaysIndicator = displaysIndicator;
	
	[self.layer setNeedsDisplay];
}

- (void)drawRect:(NSRect)dirtyRect
{
	
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
	if(_displaysIndicator == NO)
	{
		return;
	}
	
	CGContextSetLineWidth(context, 1.5 / self.layer.contentsScale);
	CGContextSetLineDash(context, 5.0, (CGFloat[]){5.,5.}, 2);
	
	CGContextSetStrokeColorWithColor(context, [NSColor.blackColor colorWithAlphaComponent:0.65].CGColor);
	CGContextMoveToPoint(context, _indicatorOffset, 0);    // This sets up the start point
	CGContextAddLineToPoint(context, _indicatorOffset, self.bounds.size.height);
	CGContextStrokePath(context);
}

@end
