//
//  DTXFileListOutlineView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/8/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXFileListOutlineView.h"

@interface NSObject ()

- (void)deleteItemAtRow:(NSInteger)row;

@end

@implementation DTXFileListOutlineView

- (void)keyDown:(NSEvent *)event
{
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	if(key == NSDeleteCharacter)
	{
		if(self.selectedRow == -1 || self.selectedRow == 0 || [self.delegate respondsToSelector:@selector(deleteItemAtRow:)] == NO)
		{
			NSBeep();
			return;
		}
		
		[(NSObject*)self.delegate deleteItemAtRow:self.selectedRow];
		
		return;
	}
	
	[super keyDown:event];
}

@end
