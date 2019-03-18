//
//  DTXValidatingButtonCell.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/18/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXValidatingButtonCell.h"

@interface NSButtonCell ()

- (void)_sendActionFrom:(id)sender;

@end

@implementation DTXValidatingButtonCell
{
	BOOL _ignoresNextAction;
}

- (void)_sendActionFrom:(id)sender
{
	if(_ignoresNextAction)
	{
		return;
	}
	
	[super _sendActionFrom:sender];
}

- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag
{
	BOOL rv = [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:flag];
	_ignoresNextAction = NO;
	return rv;
}

- (void)setNextState
{
	if(self.target != nil && [self.target respondsToSelector:@selector(validateUserInterfaceItem:)])
	{
		if([self.target validateUserInterfaceItem:(id)self.controlView] == NO)
		{
			_ignoresNextAction = YES;
			return;
		}
	}
	
	[super setNextState];
}

@end
