//
//  AppDelegate.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (IBAction)segmentCellAction:(NSSegmentedCell*)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	
	switch(selectedSegment)
	{
		case 0:
			[[NSNotificationCenter defaultCenter] postNotificationName:@"toggleBottomSubviewCollapse:" object:sender];
			break;
		case 1:
			[[NSNotificationCenter defaultCenter] postNotificationName:@"toggleRightSubviewCollapse:" object:sender];
			break;
	}
}


@end
