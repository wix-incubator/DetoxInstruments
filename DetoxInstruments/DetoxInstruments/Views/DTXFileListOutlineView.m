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
	
	[self sizeLastColumnToFit];
	[self tile];
}

@end
