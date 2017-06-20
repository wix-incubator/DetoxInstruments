//
//  DTXTimelineMouseView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXTimelineIndicatorView.h"

@import CoreImage;

@interface _DTXDashedLine : NSView
@end

@implementation _DTXDashedLine

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
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	BOOL ov = [NSGraphicsContext currentContext].shouldAntialias;
	[NSGraphicsContext currentContext].shouldAntialias = NO;
	
	[[NSColor blackColor] set];
	NSBezierPath* path = [NSBezierPath bezierPath];
	path.lineWidth = 1.5 / self.window.backingScaleFactor;
	[path moveToPoint:NSMakePoint(1, 0)];
	[path lineToPoint:NSMakePoint(1, self.bounds.size.height)];
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy:0.5 yBy:0.5];
	[path transformUsingAffineTransform:transform];
	
	CGFloat dashPattern[]={5.,5.};
	[path setLineDash:dashPattern count:sizeof(dashPattern)/sizeof(CGFloat) phase:5.0];
	
	[path stroke];
	
	[NSGraphicsContext currentContext].shouldAntialias = ov;
	
	//	[[NSColor whiteColor] setFill];
	//
	//	for (int i = 1; i < [self bounds].size.height / 10; i++) {
	//		if (i % 10 == 0) {
	//			[[NSColor colorWithSRGBRed:100/255.0 green:149/255.0 blue:237/255.0 alpha:0.3] set];
	//		} else if (i % 5 == 0) {
	//			[[NSColor colorWithSRGBRed:100/255.0 green:149/255.0 blue:237/255.0 alpha:0.2] set];
	//		} else {
	//			[[NSColor colorWithSRGBRed:100/255.0 green:149/255.0 blue:237/255.0 alpha:0.1] set];
	//		}
	//		[NSBezierPath strokeLineFromPoint:NSMakePoint(0, i * 10 - 0.5) toPoint:NSMakePoint([self bounds].size.width, i * 10 - 0.5)];
	//	}
	//	for (int i = 1; i < [self bounds].size.width / 10; i++) {
	//		if (i % 10 == 0) {
	//			[[NSColor colorWithSRGBRed:100/255.0 green:149/255.0 blue:237/255.0 alpha:0.3] set];
	//		} else if (i % 5 == 0) {
	//			[[NSColor colorWithSRGBRed:100/255.0 green:149/255.0 blue:237/255.0 alpha:0.2] set];
	//		} else {
	//			[[NSColor colorWithSRGBRed:100/255.0 green:149/255.0 blue:237/255.0 alpha:0.1] set];
	//		}
	//		[NSBezierPath strokeLineFromPoint:NSMakePoint(i * 10 - 0.5, 0) toPoint:NSMakePoint(i * 10 - 0.5, [self bounds].size.height)];
	//	}
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
		_dashedLine = [[_DTXDashedLine alloc] initWithFrame:NSMakeRect(0, 0, 2, 10000)];
		_dashedLine.hidden = YES;
		[self addSubview:_dashedLine];
		self.acceptsTouchEvents = NO;
		
		self.wantsLayer = YES;
	}
	
	return self;
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (BOOL)isFlipped
{
	return YES;
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
	_dashedLine.frame = (NSRect){floor(indicatorOffset), _dashedLine.frame.origin.y, _dashedLine.frame.size};
}

- (void)setDisplaysIndicator:(BOOL)displaysIndicator
{
	_displaysIndicator = displaysIndicator;
	_dashedLine.hidden = _displaysIndicator == NO;
}

@end
