//
//  DTXSettingsPopUpButton.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 2/19/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSettingsPopUpButton.h"

@implementation DTXSettingsPopUpButton

- (void)setMenu:(NSMenu *)menu
{
	menu = [menu copy];
	
	NSMenuItem* title = [NSMenuItem new];
	title.title = @"";
	title.image = [NSImage imageNamed:NSImageNameActionTemplate];
	
	[menu insertItem:title atIndex:0];
	
	NSMenuItem* titleGrouping = [NSMenuItem new];
	titleGrouping.title = @"Group By:";
	titleGrouping.enabled = NO;
	titleGrouping.target = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
	titleGrouping.action = @selector(test:);
	#pragma clang diagnostic pop
	
	[menu insertItem:titleGrouping atIndex:1];
	
	[super setMenu:menu];
	
	self.preferredEdge = NSMaxYEdge;
}

@end
