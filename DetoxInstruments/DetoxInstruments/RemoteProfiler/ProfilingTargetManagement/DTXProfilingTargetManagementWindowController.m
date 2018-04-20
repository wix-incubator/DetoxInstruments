//
//  DTXProfilingTargetManagementWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/19/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXProfilingTargetManagementWindowController.h"
#import "DTXContainerContentsViewController.h"
#import "DTXUserDefaultsViewController.h"

@interface DTXProfilingTargetManagementWindowController ()
{
	NSStoryboard* _storyboard;
	DTXContainerContentsViewController* _containerContentsOutlineViewController;
	DTXUserDefaultsViewController* _userDefaultsViewController;
}

@end

@implementation DTXProfilingTargetManagementWindowController

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:NSBundle.mainBundle];
		
		_containerContentsOutlineViewController = [_storyboard instantiateControllerWithIdentifier:@"DTXContainerContentsViewController"];
		[_containerContentsOutlineViewController view];
		
		_userDefaultsViewController = [_storyboard instantiateControllerWithIdentifier:@"DTXUserDefaultsViewController"];
		[_userDefaultsViewController view];
		
		self.allowsVibrancy = YES;
		self.centerToolbarItems = YES;
	}
	
	return self;
}

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget
{
	self.titleOverride = profilingTarget.appName;
	_containerContentsOutlineViewController.profilingTarget = profilingTarget;
	_userDefaultsViewController.profilingTarget = profilingTarget;
}

- (void)noteProfilingTargetDidLoadContainerContents
{
	[_containerContentsOutlineViewController noteProfilingTargetDidLoadServiceData];
}

- (void)noteProfilingTargetDidLoadUserDefaults
{
	[_userDefaultsViewController noteProfilingTargetDidLoadServiceData];
}

- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped
{
	[_containerContentsOutlineViewController showSaveDialogForSavingData:data dataWasZipped:wasZipped];
}

- (void)showPreferencesWindow
{
	[self setPreferencesViewControllers:@[_containerContentsOutlineViewController, _userDefaultsViewController]];
	
	[super showPreferencesWindow];
	
	[self.window center];
}

@end
