//
//  DTXTimelineMouseView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXTimelineIndicatorView.h"

@implementation DTXTimelineIndicatorView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		self.wantsLayer = YES;
		self.layer.rasterizationScale = 2.0;
		self.acceptsTouchEvents = NO;
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

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if(_displaysIndicator)
	{
		[[NSColor blackColor] set];
		NSBezierPath* path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(_indicatorOffset, 0)];
		[path lineToPoint:NSMakePoint(_indicatorOffset, self.bounds.size.height)];
		
		path.lineWidth = 0.75;
		
		CGFloat dashPattern[]={5.,5.};
		[path setLineDash:dashPattern count:2 phase:0.0];
		
		[path stroke];
	}
	
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

- (void)setIndicatorOffset:(CGFloat)indicatorOffset
{
	_indicatorOffset = indicatorOffset;
	
	[self setNeedsDisplay:YES];
}

- (void)setDisplaysIndicator:(BOOL)displaysIndicator
{
	_displaysIndicator = displaysIndicator;
	
	[self setNeedsDisplay:YES];
}

@end
