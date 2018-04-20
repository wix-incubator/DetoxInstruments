//
//  DTXFileListOutlineView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/8/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXFileListOutlineView.h"

@implementation DTXFileListOutlineView

-(NSMenu *)menuForEvent:(NSEvent *)event
{
	NSMenu* menu = [super menuForEvent:event];
	
	if(self.clickedRow == -1)
	{
		return nil;
	}
	
	return menu;
}

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited:(BOOL)deposited
{
	return NO;
}

- (void)layout
{
	[super layout];
	
	self.outlineTableColumn.maxWidth = self.bounds.size.width - 2;
	self.outlineTableColumn.width = self.bounds.size.width - 2;
	[self tile];
	[self setNeedsLayout:YES];
	[self layoutSubtreeIfNeeded];
}

@end
