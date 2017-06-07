//
//  DTXPlotTableView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 02/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPlotTableView.h"

IB_DESIGNABLE
@implementation DTXPlotTableView

- (void)drawGridInClipRect:(NSRect)clipRect
{	
	NSRect lastRowRect = [self rectOfRow:[self numberOfRows] - 1];
	NSRect myClipRect = NSMakeRect(0, 0, lastRowRect.size.width, NSMaxY(lastRowRect));
	NSRect finalClipRect = NSIntersectionRect(clipRect, myClipRect);
	[super drawGridInClipRect:finalClipRect];
}

@end
