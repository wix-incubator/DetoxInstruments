//
//  CCNPreferencesWindowController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/16/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#if DEBUG

#import "CCNPreferencesWindowController+DocumentationGeneration.h"

@interface CCNPreferencesWindowController ()

- (void)activateViewController:(id<CCNPreferencesWindowControllerProtocol>)viewController animate:(BOOL)animate;

@end

@implementation CCNPreferencesWindowController (DocumentationGeneration)

- (void)_drainLayout
{
	[self.window layoutIfNeeded];
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
}

- (void)_activateControllerAtIndex:(NSUInteger)index
{
	id vc = [[self valueForKey:@"viewControllers"] objectAtIndex:index];
	self.window.toolbar.selectedItemIdentifier = [vc preferenceIdentifier];
	[self activateViewController:vc animate:NO];
}


@end

#endif
