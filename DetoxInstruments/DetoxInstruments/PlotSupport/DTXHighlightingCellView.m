//
//  DTXHighlightingCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXHighlightingCellView.h"

@implementation DTXHighlightingCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	self.textField.textColor = backgroundStyle == NSBackgroundStyleDark ? [NSColor selectedTextColor] : [NSColor textColor];
}

@end
