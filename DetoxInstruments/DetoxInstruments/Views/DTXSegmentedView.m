//
//  DTXSegmentedView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 15/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSegmentedView.h"

@interface DTXSegmentedCell : NSSegmentedCell @end

@implementation DTXSegmentedCell

- (void)_drawBackgroundWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	
}

@end

@implementation DTXSegmentedView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.target = self;
	self.action = @selector(_segmentCellAction:);
}

- (IBAction)_segmentCellAction:(NSSegmentedCell*)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	[sender setSelected:YES forSegment:selectedSegment];
	[sender setSelected:NO forSegment:1 - selectedSegment];
	
	[sender setImage:[NSImage imageNamed:[sender isSelectedForSegment:0] ? @"extendedInfo_highlighted": @"extendedInfo"] forSegment:0];
	[sender setImage:[NSImage imageNamed:[sender isSelectedForSegment:1] ? @"fileInfo_highlighted" : @"fileInfo"] forSegment:1];
	
	[self.delegate segmentedView:self didSelectSegmentAtIndex:selectedSegment];
}

@end
