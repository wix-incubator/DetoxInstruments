//
//  DTXHighlightingAttributedTextField.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/08/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXHighlightingAttributedTextField.h"

@implementation DTXHighlightingAttributedTextField
{
	NSAttributedString* _normalString;
	NSMutableAttributedString* _highlightedString;
}

- (void)setAttributedStringValue:(NSAttributedString *)attributedStringValue
{
	_normalString = [attributedStringValue copy];
	_highlightedString = [_normalString mutableCopy];
	[_highlightedString addAttribute:NSForegroundColorAttributeName value:NSColor.alternateSelectedControlTextColor range:NSMakeRange(0, _normalString.length)];
	
	[super setAttributedStringValue:self.isHighlighted ? _highlightedString : _normalString];
}

- (void)setHighlighted:(BOOL)highlighted
{
	if(self.isHighlighted == highlighted)
	{
		return;
	}
	
	[super setHighlighted:highlighted];
	
	[super setAttributedStringValue:self.isHighlighted ? _highlightedString : _normalString];
}

@end
