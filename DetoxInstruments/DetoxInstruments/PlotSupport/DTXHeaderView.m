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
	self.layer.backgroundColor = NSColor.whiteColor .CGColor;
	self.layer.masksToBounds = NO;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
	NSBezierPath* line = [NSBezierPath bezierPath];
	
	[line moveToPoint:NSMakePoint(0, 0)];
	[line lineToPoint:NSMakePoint(self.bounds.size.width, 0)];
	
	[line moveToPoint:NSMakePoint(179.5, 0)];
	[line lineToPoint:NSMakePoint(179.5, self.bounds.size.height)];
	
	line.lineWidth = 1;
	[NSColor.gridColor set];
	[line stroke];
}

@end
