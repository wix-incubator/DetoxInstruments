//
//  DTXAsyncStorageViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/12/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXAsyncStorageViewController.h"
@import LNPropertyListEditor;

@interface DTXAsyncStorageViewController () <LNPropertyListEditorDelegate>
{
	IBOutlet LNPropertyListEditor* _plistEditor;
	IBOutlet NSButton* _helpButton;
	IBOutlet NSButton* _refreshButton;
}
@end

@implementation DTXAsyncStorageViewController

@synthesize profilingTarget=_profilingTarget;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_plistEditor.delegate = self;
	_plistEditor.typeColumnHidden = YES;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[_plistEditor.window makeFirstResponder:[_plistEditor valueForKey:@"outlineView"]];
}

- (void)setProfilingTarget:(DTXRemoteTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	if(profilingTarget == nil)
	{
		return;
	}
	
	[self.profilingTarget loadAsyncStorage];
}

- (IBAction)refresh:(id)sender
{
	[self.profilingTarget loadAsyncStorage];
}

- (IBAction)clear:(id)sender
{
	[self.profilingTarget clearAsyncStorage];
	_plistEditor.propertyList = @{};
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
	_plistEditor.propertyList = self.profilingTarget.asyncStorage;
}

#pragma mark CCNPreferencesWindowControllerProtocol

- (NSImage *)preferenceIcon
{
	return [NSImage imageNamed:@"AsyncStorage"];
}

- (NSString *)preferenceIdentifier
{
	return @"AsyncStorage";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"Async Storage", @"");
}

#pragma mark LNPropertyListEditorDelegate

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditTypeOfNode:(LNPropertyListNode*)node
{
	return NO;
}

- (void)propertyListEditor:(LNPropertyListEditor *)editor willChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey
{
	LNPropertyListNode* childOfParent = [editor.rootPropertyListNode childNodeContainingDescendantNode:node];
	
	[self.profilingTarget changeAsyncStorageItemWithKey:childOfParent.key changeType:childOfParent == node ? (DTXRemoteProfilingChangeType)changeType : DTXRemoteProfilingChangeTypeUpdate value:childOfParent.propertyList previousKey:childOfParent == node ? previousKey : nil];
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canPasteNode:(LNPropertyListNode *)pastedNode inNode:(LNPropertyListNode *)node
{
	return pastedNode.type == LNPropertyListNodeTypeString;
}

@end
