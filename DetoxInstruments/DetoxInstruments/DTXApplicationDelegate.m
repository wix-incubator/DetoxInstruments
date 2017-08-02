//
//  AppDelegate.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXApplicationDelegate.h"

@interface DTXApplicationDelegate ()

@end

@implementation DTXApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (IBAction)openGitHubPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/wix/DetoxInstruments"]];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
{
	return YES;
}
//
//- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender
//{
//	return NO;
//}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	return flag;
}

@end
