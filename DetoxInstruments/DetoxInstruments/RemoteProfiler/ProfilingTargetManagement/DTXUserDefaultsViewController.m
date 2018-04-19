//
//  DTXUserDefaultsViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/18/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXUserDefaultsViewController.h"
@import LNPropertyListEditor;

@interface DTXUserDefaultsViewController ()
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
	
	self.view.wantsLayer = YES;
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

- (void)noteProfilingTargetDidLoadServiceData
{
	_plistEditor.propertyList = self.profilingTarget.userDefaults;
}

#pragma mark CCNPreferencesWindowControllerProtocol

- (NSImage *)preferenceIcon
{
	NSImage* image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarCustomizeIcon)];
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

@end
