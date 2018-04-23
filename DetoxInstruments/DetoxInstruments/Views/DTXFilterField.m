//
//  DTXFilterField.m
//  DetoxInstruments
//
//  Created by Artal Druk on 28/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXFilterField.h"
#import "ImageGenerator.h"

@implementation DTXFilterField

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.delegate = self;
	self.centersPlaceholder = NO;
	
	[self setCancelIcon];
	[self setSearchIconWithHighlight:NO];
}

- (void)setCancelIcon
{
	NSButtonCell *cancelButtonCell = ((NSSearchFieldCell*)self.cell).cancelButtonCell;
	cancelButtonCell.image = cancelButtonCell.alternateImage = [ImageGenerator createCancelImageWithSize:11];
}

- (void)setSearchIconWithHighlight:(BOOL)highlighted
{
	NSButtonCell *searchButtonCell = ((NSSearchFieldCell*)self.cell).searchButtonCell;
	searchButtonCell.image = searchButtonCell.alternateImage = [ImageGenerator createFilterImageWithSize:18 highlighted:highlighted];
}

- (NSRect)rectForSearchTextWhenCentered:(BOOL)isCentered
{
	return CGRectOffset([super rectForSearchTextWhenCentered:isCentered], 3, 0);
}

- (void)searchFieldDidStartSearching:(NSSearchField *)sender
{
	[self setSearchIconWithHighlight:YES];
}

- (void)searchFieldDidEndSearching:(NSSearchField *)sender
{
	[self setSearchIconWithHighlight:NO];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
	[self.filterDelegate filterFieldTextDidChange:self];
}

//This somehow makes the image image be drawn.
- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
}

- (void)clearFilter
{
	NSButtonCell* buttonCell = ((NSSearchFieldCell*)self.cell).cancelButtonCell;
	
	[NSApp sendAction:buttonCell.action to:buttonCell.target from:buttonCell];
}

@end
