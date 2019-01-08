//
//  DTXProfilingTargetManagementWindowController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/15/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXProfilingTargetManagementWindowController+DocumentationGeneration.h"

@interface NSObject ()

- (id)childNodeForKey:(NSString*)key;

@end

@interface DTXProfilingTargetManagementWindowController ()

- (void)activateViewController:(id<CCNPreferencesWindowControllerProtocol>)viewController animate:(BOOL)animate;

@end

@implementation DTXProfilingTargetManagementWindowController (DocumentationGeneration)

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

- (void)_expandFolders
{
	NSOutlineView* outline = [[[self valueForKey:@"viewControllers"] objectAtIndex:0] valueForKey:@"outlineView"];
	[outline expandItem:nil expandChildren:YES];
}

- (void)_expandDefaults
{
	NSOutlineView* outline = [[[self valueForKey:@"viewControllers"] objectAtIndex:2] valueForKeyPath:@"plistEditor.outlineView"];
	[outline expandItem:nil expandChildren:YES];
}

- (void)_expandCookies
{
	NSOutlineView* outline = [[[self valueForKey:@"viewControllers"] objectAtIndex:3] valueForKeyPath:@"plistEditor.outlineView"];
	[outline expandItem:nil expandChildren:YES];
}

- (void)_selectDateInCookies
{
	id controller = [[self valueForKey:@"viewControllers"] objectAtIndex:3];
	NSOutlineView* outline = [controller valueForKeyPath:@"plistEditor.outlineView"];
	id node = [[[controller valueForKeyPath:@"plistEditor.rootPropertyListNode.children"] objectAtIndex:0] childNodeForKey:@"Expires"];
	NSInteger row = [outline rowForItem:node];
	[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	NSControl* datePicker = [[outline viewAtColumn:2 row:row makeIfNecessary:NO] valueForKeyPath:@"datePicker.datePicker"];
	[datePicker.window makeFirstResponder:datePicker];
}

- (void)_selectSomethingInDefaults
{
	id controller = [[self valueForKey:@"viewControllers"] objectAtIndex:2];
	NSOutlineView* outline = [controller valueForKeyPath:@"plistEditor.outlineView"];
	id node = [[controller valueForKeyPath:@"plistEditor.rootPropertyListNode.children"] objectAtIndex:2];
	NSInteger row = [outline rowForItem:node];
	[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	NSControl* textField = [[outline viewAtColumn:2 row:row makeIfNecessary:NO] valueForKeyPath:@"textField"];
	[textField.window makeFirstResponder:textField];
}

@end
