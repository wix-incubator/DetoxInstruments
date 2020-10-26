//
//  DTXSegmentedView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 15/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
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
	NSImage* extendedImage;
	NSImage* fileImage;
	if(@available(macOS 11.0, *))
	{
		extendedImage = [[NSImage imageWithSystemSymbolName:[NSString stringWithFormat:@"e.square%@", [self isSelectedForSegment:0] ? @".fill" : @""] accessibilityDescription:nil] imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:15 weight:NSFontWeightRegular]];
		fileImage = [[NSImage imageWithSystemSymbolName:[NSString stringWithFormat:@"doc%@", [self isSelectedForSegment:1] ? @".fill" : @""] accessibilityDescription:nil] imageWithSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:14 weight:NSFontWeightRegular]];
	}
	else
	{
		extendedImage = [NSImage imageNamed:[self isSelectedForSegment:0] ? @"extendedInfo_highlighted": @"extendedInfo"];
		fileImage = [NSImage imageNamed:[self isSelectedForSegment:1] ? @"fileInfo_highlighted" : @"fileInfo"];
	}
	
	[self setImage:extendedImage forSegment:0];
	[self setImage:fileImage forSegment:1];
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
