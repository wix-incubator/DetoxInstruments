//
//  DTXTextViewCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXTextViewCellView.h"

@interface DTXTextViewCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSTextView* textView;

@end

@implementation DTXTextViewCellView

- (NSView *)hitTest:(NSPoint)aPoint
{
	return self.textView.selectable ? [super hitTest:aPoint] : nil;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	if(self.textView.selectable == NO)
	{
		self.textView.textColor = backgroundStyle == NSBackgroundStyleDark ? [NSColor whiteColor] : [NSColor blackColor];
	}
}

@end
