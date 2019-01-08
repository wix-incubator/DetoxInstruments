//
//  DTXMenuPathContro.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 09/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXMenuPathControl.h"

@implementation DTXMenuPathControl

@dynamic delegate;

- (void)mouseDown:(NSEvent *)event
{
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	
	NSPathCell *cell = self.cell;
	NSPathComponentCell *componentCell = [cell pathComponentCellAtPoint:point withFrame:self.bounds inView:self];
	
	if(componentCell == nil)
	{
		[super mouseDown:event];
		
		return;
	}
	
	NSRect componentRect = [cell rectOfPathComponentCell:componentCell withFrame:self.bounds inView:self];
	
	NSMenu *menu = [self.delegate pathControl:self menuForCell:componentCell];
	
	if (menu.numberOfItems > 0)
	{
		NSUInteger selectedMenuItemIndex = 0;
		for (NSUInteger menuItemIndex = 0; menuItemIndex < menu.numberOfItems; menuItemIndex++)
		{
			if ([[menu itemAtIndex:menuItemIndex] state] == NSControlStateValueOn)
			{
				selectedMenuItemIndex = menuItemIndex;
				break;
			}
		}
		
		NSMenuItem *selectedMenuItem = [menu itemAtIndex:selectedMenuItemIndex];
		[menu popUpMenuPositioningItem:selectedMenuItem atLocation:NSMakePoint(NSMinX(componentRect) - 15, NSMinY(componentRect) + 1) inView:self];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	if (event.type != NSEventTypeLeftMouseDown)
	{
		return nil;
	}
	return [super menuForEvent:event];
}

@end
