//
//  DTXPlotRowView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPlotRowView.h"

@implementation DTXPlotRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	[self.selectionColor setFill];
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	CGContextFillRect(ctx, CGRectMake(0, dirtyRect.origin.y, 210.5, dirtyRect.origin.y + dirtyRect.size.height));
}

- (BOOL)wantsUpdateLayer
{
	return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	
	[NSColor.gridColor set];
	CGContextSetLineWidth(ctx, 1);
	CGContextMoveToPoint(ctx, 210.5, dirtyRect.origin.y);
	CGContextAddLineToPoint(ctx, 210.5, dirtyRect.origin.y + dirtyRect.size.height);
	CGContextStrokePath(ctx);
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.canDrawSubviewsIntoLayer = YES;
}

@end
