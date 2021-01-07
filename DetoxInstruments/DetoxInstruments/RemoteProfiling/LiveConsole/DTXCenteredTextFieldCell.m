//
//  DTXCenteredTextFieldCell.m
//  DetoxInstruments
//
//  Created by Leo Natan on 9/2/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXCenteredTextFieldCell.h"

@implementation DTXCenteredTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect {
	NSRect titleFrame = [super titleRectForBounds:theRect];
	NSSize titleSize = [[self attributedStringValue] size];
	titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
	return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect titleRect = [self titleRectForBounds:cellFrame];
	[[self attributedStringValue] drawInRect:titleRect];
}

@end
