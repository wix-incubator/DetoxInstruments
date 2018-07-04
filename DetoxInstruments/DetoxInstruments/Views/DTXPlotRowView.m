//
//  DTXPlotRowView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotRowView.h"

@implementation DTXPlotRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	[self.selectionColor setFill];
	[[NSBezierPath bezierPathWithRect:NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y, 210.5, dirtyRect.size.height - 1)] fill];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	NSBezierPath* line = [NSBezierPath bezierPath];
	
	[line moveToPoint:NSMakePoint(210.5, 0)];
	[line lineToPoint:NSMakePoint(210.5, self.bounds.size.height)];
	
	line.lineWidth = 1.0;
	[NSColor.gridColor set];
	[line stroke];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.canDrawSubviewsIntoLayer = YES;
}

@end
