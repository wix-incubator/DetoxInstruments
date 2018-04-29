//
//  DTXUserDefaultsViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/18/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXUserDefaultsViewController.h"
@import LNPropertyListEditor;

@interface DTXUserDefaultsViewController () <LNPropertyListEditorDelegate>
{
	IBOutlet LNPropertyListEditor* _plistEditor;
	IBOutlet NSButton* _helpButton;
	IBOutlet NSButton* _refreshButton;
}
@end

@implementation DTXUserDefaultsViewController

@synthesize profilingTarget=_profilingTarget;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_plistEditor.delegate = self;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[_plistEditor.window makeFirstResponder:[_plistEditor valueForKey:@"outlineView"]];
}

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	if(profilingTarget == nil)
	{
		return;
	}
	
	[self.profilingTarget loadUserDefaults];
}

- (IBAction)refresh:(id)sender
{
	[self.profilingTarget loadUserDefaults];
}

- (IBAction)save:(id)sender
{
	//Make users feel good; nothing needs to be done here.
}

- (IBAction)saveDocument:(id)sender
{
	[self save:sender];
}

- (void)noteProfilingTargetDidLoadServiceData
{
	_plistEditor.propertyList = self.profilingTarget.userDefaults;
}

#pragma mark CCNPreferencesWindowControllerProtocol

- (NSImage *)preferenceIcon
{
	NSImage* image = [NSImage imageNamed:@"NSToolbarCustomizeToolbarItemImage"];
	image.size = NSMakeSize(32, 32);
	
	return image;
}

- (NSString *)preferenceIdentifier
{
	return @"UserDefaults";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"User Defaults", @"");
}

#pragma mark LNPropertyListEditorDelegate

- (void)propertyListEditor:(LNPropertyListEditor *)editor willChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey
{
	LNPropertyListNode* childOfParent = [editor.rootPropertyListNode childNodeContainingDescendantNode:node];
	
	[self.profilingTarget changeUserDefaultsItemWithKey:childOfParent.key changeType:childOfParent == node ? (DTXUserDefaultsChangeType)changeType : DTXUserDefaultsChangeTypeUpdate value:childOfParent.propertyList previousKey:childOfParent == node ? previousKey : nil];
}

@end
