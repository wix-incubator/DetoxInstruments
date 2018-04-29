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

@interface DTXProfilingTargetManagementWindowController ()
{
	NSStoryboard* _storyboard;
	DTXContainerContentsViewController* _containerContentsOutlineViewController;
	DTXUserDefaultsViewController* _userDefaultsViewController;
	DTXCookiesViewController* _cookiesViewController;
	
	NSArray<id<DTXProfilingTargetManagement>>* _controllers;
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
		
		_cookiesViewController = [_storyboard instantiateControllerWithIdentifier:@"DTXCookiesViewController"];
		[_cookiesViewController view];
		
		_controllers = @[_containerContentsOutlineViewController, _userDefaultsViewController, _cookiesViewController];
		
		self.allowsVibrancy = NO;
		self.centerToolbarItems = YES;
	}
	
	return self;
}

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget
{
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

- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped
{
	[_containerContentsOutlineViewController showSaveDialogForSavingData:data dataWasZipped:wasZipped];
}

- (void)showPreferencesWindow
{
	if([self.window isVisible])
	{
		[self.window makeKeyAndOrderFront:nil];
		
		return;
	}
	
	[self setPreferencesViewControllers:_controllers];
	
	[super showPreferencesWindow];
	
	[self.window center];
}

@end
