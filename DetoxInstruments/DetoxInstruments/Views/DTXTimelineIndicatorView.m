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

@interface _DTXDashedLine : NSView <CALayerDelegate>
@end

@implementation _DTXDashedLine

- (CALayer *)makeBackingLayer
{
	return [_DTXDashedLineLayer new];
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
	
	[self setNeedsDisplay:YES];
}

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
}

@end

@implementation DTXTimelineIndicatorView
{
	_DTXDashedLine* _dashedLine;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		self.wantsLayer = YES;
		_dashedLine = [[_DTXDashedLine alloc] initWithFrame:NSMakeRect(0, 0, 1, frameRect.size.height)];
		_dashedLine.hidden = YES;
		_dashedLine.wantsLayer = YES;
		_dashedLine.layer.backgroundColor = [NSColor.blackColor colorWithAlphaComponent:0.45].CGColor;
		[self addSubview:_dashedLine];
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
	
	_dashedLine.frame = (NSRect){floor(_indicatorOffset), _dashedLine.frame.origin.y, 1 / self.layer.contentsScale, self.bounds.size.height};
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

//- (BOOL)isFlipped
//{
//	return YES;
//}

- (void)layout
{
	[super layout];
	
	CGRect frame = _dashedLine.frame;
	frame.size.height = self.bounds.size.height;
	_dashedLine.frame = frame;
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
	//Causes bug in High Sierra
	if(NSProcessInfo.processInfo.operatingSystemVersion.minorVersion <= 12)
	{
		_dashedLine.frame = (NSRect){floor(indicatorOffset), _dashedLine.frame.origin.y, _dashedLine.frame.size};
	}
}

- (void)setDisplaysIndicator:(BOOL)displaysIndicator
{
	_displaysIndicator = displaysIndicator;
	//Causes bug in High Sierra
	if(NSProcessInfo.processInfo.operatingSystemVersion.minorVersion <= 12)
	{
		_dashedLine.hidden = _displaysIndicator == NO;
	}
}

@end
