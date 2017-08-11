//
//  DTXHeaderView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXHeaderView.h"

@implementation DTXHeaderView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
}

- (void)viewDidMoveToWindow
{
	[self viewDidChangeBackingProperties];
}

-(void)viewDidChangeBackingProperties
{
//	if (self.window)
//	{
//		self.layer.contentsScale = self.window.backingScaleFactor;
//	}
//	else
//	{
//		self.layer.contentsScale = 1.0;
//	}
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	BOOL ov = [NSGraphicsContext currentContext].shouldAntialias;
	[NSGraphicsContext currentContext].shouldAntialias = NO;
	
	NSBezierPath* line = [NSBezierPath bezierPath];
	line.lineWidth = 1 / self.window.backingScaleFactor;
	
	[line moveToPoint:NSMakePoint(0, 0)];
	[line lineToPoint:NSMakePoint(self.bounds.size.width, 0)];
	
	[line moveToPoint:NSMakePoint(209.5, 0)];
	[line lineToPoint:NSMakePoint(209.5, self.bounds.size.height)];
	
	[NSColor.gridColor set];
	[line stroke];
	
	[NSGraphicsContext currentContext].shouldAntialias = ov;
}

@end
