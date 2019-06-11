//
//  DTXInstrumentsPreferencesWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/11/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXInstrumentsPreferencesWindowController.h"
#import "DTXDisplayPreferencesViewController.h"

@interface DTXInstrumentsPreferencesWindowController ()

@end

@implementation DTXInstrumentsPreferencesWindowController

- (void)showPreferencesWindow
{
	if([self.window isVisible])
	{
		[self.window makeKeyAndOrderFront:nil];
		
		return;
	}
	
	if(self.window == nil)
	{
		[self loadWindow];
	}
	
	NSStoryboard* sb = [NSStoryboard storyboardWithName:@"Preferences" bundle:nil];
	
	[self setPreferencesViewControllers:@[[sb instantiateControllerWithIdentifier:@"DisplayPreferences"], [sb instantiateControllerWithIdentifier:@"RecordingPreferences"]]];
	self.centerToolbarItems = NO;
	
	[super showPreferencesWindow];
	
	self.window.styleMask &= ~NSWindowStyleMaskMiniaturizable;
	[self.window center];
}

@end
