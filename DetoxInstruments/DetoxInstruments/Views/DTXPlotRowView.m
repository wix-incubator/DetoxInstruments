//
//  DTXPlotRowView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotRowView.h"

@implementation DTXPlotRowView

//- (void)drawSelectionInRect:(NSRect)dirtyRect
//{
//	[self.selectionColor setFill];
//	[[NSBezierPath bezierPathWithRect:NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y, 209.5, dirtyRect.size.height)] fill];
//}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.canDrawSubviewsIntoLayer = YES;
}

@end
