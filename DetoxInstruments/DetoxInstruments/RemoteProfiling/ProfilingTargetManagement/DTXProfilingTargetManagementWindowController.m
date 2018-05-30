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
#import "DTXCookiesViewController.h"
#import "DTXPasteboardViewController.h"

@interface DTXProfilingTargetManagementWindowController ()
{
	NSStoryboard* _storyboard;
	DTXContainerContentsViewController* _containerContentsOutlineViewController;
	DTXUserDefaultsViewController* _userDefaultsViewController;
	DTXCookiesViewController* _cookiesViewController;
	DTXPasteboardViewController* _pasteboardViewController;
	
	NSArray<id<DTXProfilingTargetManagement>>* _controllers;
}

@end

@implementation DTXProfilingTargetManagementWindowController

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_storyboard = [NSStoryboard storyboardWithName:@"TargetManagement" bundle:NSBundle.mainBundle];
		
		self.allowsVibrancy = NO;
		self.centerToolbarItems = YES;
	}
	
	return self;
}

- (void)setProfilingTarget:(DTXRemoteTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	self.titleOverride = [NSString stringWithFormat:@"%@ — %@", profilingTarget.appName, profilingTarget.deviceName];
	
	[_controllers enumerateObjectsUsingBlock:^(id<DTXProfilingTargetManagement>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj setProfilingTarget:profilingTarget];
	}];
}

- (void)noteProfilingTargetDidLoadContainerContents
{
	[_containerContentsOutlineViewController noteProfilingTargetDidLoadServiceData];
}

- (void)noteProfilingTargetDidLoadUserDefaults
{
	[_userDefaultsViewController noteProfilingTargetDidLoadServiceData];
}

- (void)noteProfilingTargetDidLoadCookies
{
	[_cookiesViewController noteProfilingTargetDidLoadServiceData];
}

- (void)noteProfilingTargetDidLoadPasteboardContents
{
	[_pasteboardViewController noteProfilingTargetDidLoadServiceData];
}

- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped
{
	if(self.window.isVisible == NO)
	{
		//Window is hidden—do not display the save dialog.
		return;
	}
	
	[_containerContentsOutlineViewController showSaveDialogForSavingData:data dataWasZipped:wasZipped];
}

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
	
	_containerContentsOutlineViewController = [_storyboard instantiateControllerWithIdentifier:@"DTXContainerContentsViewController"];
	[_containerContentsOutlineViewController view];
	
	_userDefaultsViewController = [_storyboard instantiateControllerWithIdentifier:@"DTXUserDefaultsViewController"];
	[_userDefaultsViewController view];
	
	_cookiesViewController = [_storyboard instantiateControllerWithIdentifier:@"DTXCookiesViewController"];
	[_cookiesViewController view];
	
	_pasteboardViewController = [_storyboard instantiateControllerWithIdentifier:@"DTXPasteboardViewController"];
	[_pasteboardViewController view];
	
	_controllers = @[_containerContentsOutlineViewController, _pasteboardViewController, _userDefaultsViewController, _cookiesViewController];
	
	[_controllers enumerateObjectsUsingBlock:^(id<DTXProfilingTargetManagement>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj setProfilingTarget:self.profilingTarget];
	}];
	
	[self setPreferencesViewControllers:_controllers];
	
//	self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
	
	[super showPreferencesWindow];
	
	[self.window center];
}

@end
