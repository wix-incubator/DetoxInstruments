//
//  DTXHighlightingCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXHighlightingCellView.h"

@implementation DTXHighlightingCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	NSBezierPath* line = [NSBezierPath bezierPath];
	
	[line moveToPoint:NSMakePoint(self.bounds.size.width, 0)];
	[line lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
	
	line.lineWidth = 2.0;
	[NSColor.gridColor set];
	[line stroke];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	self.textField.textColor = backgroundStyle == NSBackgroundStyleDark ? [NSColor selectedTextColor] : [NSColor textColor];
}

@end
