//
//  DTXAboutWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/25/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXAboutWindowController.h"

@implementation DTXAboutWindow

- (void)keyDown:(NSEvent *)event
{
	//Escape
	if(event.keyCode == 53)
	{
		[self close];
		return;
	}
	
	[super keyDown:event];
}

@end

@implementation DTXAboutWindowController

@end
