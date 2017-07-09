//
//  DTXScrollIgnoringScrollView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 15/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
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
		height += [tbl.delegate tableView:tbl heightOfRow:idx] + tbl.intercellSpacing.height;
	}
	
	return NSMakeSize(1, height);
}

@end
