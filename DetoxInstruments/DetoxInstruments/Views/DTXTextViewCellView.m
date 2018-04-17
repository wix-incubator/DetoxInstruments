//
//  DTXTextViewCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXTextViewCellView.h"
#import "NSColor+UIAdditions.h"

@interface DTXTextViewCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSTextField* contentTextField;

@end

@implementation DTXTextViewCellView

- (NSView *)hitTest:(NSPoint)aPoint
{
	return self.contentTextField.selectable ? [super hitTest:aPoint] : nil;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	if(self.contentTextField.selectable == NO)
	{
		self.contentTextField.textColor = backgroundStyle == NSBackgroundStyleDark ? [NSColor selectedTextColor] : [NSColor textColor];
	}
}

@end
