//
//  DTXScrollIgnoringScrollView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 15/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXScrollIgnoringScrollView.h"

@implementation DTXScrollIgnoringScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
	[[self nextResponder] scrollWheel:theEvent];
}

- (NSSize)intrinsicContentSize
{
	if([self.documentView isKindOfClass:[NSTableView class]] == NO)
	{
		return [super intrinsicContentSize];
	}
	
	NSTableView* tbl = self.documentView;
	
	CGFloat height = 0;
	
	for(NSUInteger idx = 0; idx < tbl.numberOfRows; idx ++)
	{
		CGFloat rowHeight = 0;
		
		if([tbl isKindOfClass:[NSOutlineView class]])
		{
			NSOutlineView* outline = (id)tbl;
			id item = [outline itemAtRow:idx];
			rowHeight = [outline.delegate outlineView:outline heightOfRowByItem:item];
		}
		else if([tbl isKindOfClass:[NSTableView class]])
		{
			rowHeight = [tbl.delegate tableView:tbl heightOfRow:idx];
		}
		
		
		height += rowHeight + tbl.intercellSpacing.height;
	}
	
	return NSMakeSize(-1, height);
}

@end
