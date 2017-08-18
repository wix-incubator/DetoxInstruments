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

- (void)fixIcons
{
	[self.cell setImage:[NSImage imageNamed:[self.cell isSelectedForSegment:0] ? @"extendedInfo_highlighted": @"extendedInfo"] forSegment:0];
	[self.cell setImage:[NSImage imageNamed:[self.cell isSelectedForSegment:1] ? @"fileInfo_highlighted" : @"fileInfo"] forSegment:1];
}

- (IBAction)_segmentCellAction:(NSSegmentedCell*)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	[sender setSelected:YES forSegment:selectedSegment];
	[sender setSelected:NO forSegment:1 - selectedSegment];
	
	[self fixIcons];
	
	[self.delegate segmentedView:self didSelectSegmentAtIndex:selectedSegment];
}

- (void)setSelectedSegment:(NSInteger)selectedSegment
{
	for(NSUInteger idx = 0; idx < self.segmentCount; idx++)
	{
		[self setSelected:selectedSegment == idx forSegment:idx];
	}
	
	[self fixIcons];
}

@end
