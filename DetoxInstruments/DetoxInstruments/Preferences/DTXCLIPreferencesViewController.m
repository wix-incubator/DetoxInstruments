//
//  DTXCLIPreferencesViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/23/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXCLIPreferencesViewController.h"
#import "CCNPreferencesWindowControllerProtocol.h"
#import "DTXApplicationDelegate-Private.h"

@interface DTXCLIPreferencesViewController () <CCNPreferencesWindowControllerProtocol>

@end

@implementation DTXCLIPreferencesViewController
{
	NSImage* _consoleAppImage;
	
	__weak IBOutlet NSButton *_installButton;
	__weak IBOutlet NSTextField *_installedAtLabel;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSString* path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.Console"];
	_consoleAppImage = [[NSWorkspace sharedWorkspace] iconForFile:path] ?: [NSImage imageNamed:@"console_small"];
}

- (NSImage *)preferenceIcon
{
	NSImage* image;
	if(@available(macOS 11.0, *))
	{
		image = [NSImage imageWithSystemSymbolName:@"note.text" accessibilityDescription:nil];
	}
	else
	{
		image = _consoleAppImage;
	}
	
	return image;
}

- (NSString *)preferenceIdentifier
{
	return @"CLI";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"CLI Utility", @"");
}

- (void)_reloadState
{
	_installButton.title = NSLocalizedString(@"Install", @"");
	
	if(DTXInstrumentsUtils.isUnsupportedVersion)
	{
		_installButton.enabled = NO;
		_installedAtLabel.hidden = YES;
		return;
	}
	
	DTXApplicationDelegate* appDelegate = (DTXApplicationDelegate*)NSApp.delegate;
	
	NSUInteger integrationState = appDelegate._CLIInstallationStatus;
	
	switch (integrationState) {
		case 0:
			_installButton.title = NSLocalizedString(@"Install", @"");
			_installButton.action = @selector(_installCLIIntegration);
			_installedAtLabel.hidden = YES;
			break;
		case 1:
			_installButton.title = NSLocalizedString(@"Uninstall", @"");
			_installButton.action = @selector(_uninstallCLIIntegration);
			_installedAtLabel.hidden = NO;
			_installedAtLabel.stringValue = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Installed at:", @""), appDelegate._CLIInstallURL.path];
			break;
		case 2:
			_installButton.title = NSLocalizedString(@"Repair", @"");
			_installButton.action = @selector(_installCLIIntegration);
			_installedAtLabel.hidden = NO;
			_installedAtLabel.stringValue = [NSString stringWithFormat:@"⚠️ %@ %@", NSLocalizedString(@"Installed at:", @""), appDelegate._CLIInstallURL.path];
			break;
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_reloadState) name:DTXCLIToolsInstallStatusChanged object:nil];
	
	[self _reloadState];
}



@end
