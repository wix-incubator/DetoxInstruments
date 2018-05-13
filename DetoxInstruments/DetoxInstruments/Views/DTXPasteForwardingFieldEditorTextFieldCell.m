//
//  DTXPasteForwardingFieldEditorTextFieldCell.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/13/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPasteForwardingFieldEditorTextFieldCell.h"

@interface DTXPasteForwardingFieldEditor : NSTextView @end

@implementation DTXPasteForwardingFieldEditor

- (BOOL)isFieldEditor
{
	return YES;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if(aSelector == @selector(paste:))
	{
		return NO;
	}
	
	return [super respondsToSelector:aSelector];
}

@end

@implementation DTXPasteForwardingFieldEditorTextFieldCell

- (NSTextView *)fieldEditorForView:(NSView *)controlView
{
	return [DTXPasteForwardingFieldEditor new];
}

@end
