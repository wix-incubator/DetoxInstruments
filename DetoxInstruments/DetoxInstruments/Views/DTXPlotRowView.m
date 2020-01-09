//
//  DTXPlotRowView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXPlotRowView.h"

@implementation DTXPlotRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	[self.selectionColor setFill];
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	CGContextFillRect(ctx, CGRectMake(0, dirtyRect.origin.y, _tableView.tableColumns.firstObject.width + 0.5, dirtyRect.origin.y + dirtyRect.size.height));
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
	CGContextMoveToPoint(ctx, _tableView.tableColumns.firstObject.width + 0.5, dirtyRect.origin.y);
	CGContextAddLineToPoint(ctx, _tableView.tableColumns.firstObject.width + 0.5, dirtyRect.origin.y + dirtyRect.size.height);
	CGContextStrokePath(ctx);
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.canDrawSubviewsIntoLayer = YES;
}

@end
