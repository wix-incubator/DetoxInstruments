//
//  AppDelegate.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXApplicationDelegate.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "DTXRecordingDocument.h"
#import "DTXAboutWindowController.h"
#import "DTXColorTryoutsWindow.h"
#import "DTXMeasurements.h"

#import "DTXLogging.h"
DTX_CREATE_LOG(ApplicationDelegate)

@import Carbon;
@import Sparkle;

OSStatus DTXGoToHelpPage(NSString* pagePath)
{
	if(pagePath)
	{
		pagePath = [NSString stringWithFormat:@"Documentation/%@.html", pagePath];
	}

	CFBundleRef myApplicationBundle = NULL;
	CFStringRef myBookName = NULL;

	myApplicationBundle = CFBundleGetMainBundle();
	if (myApplicationBundle == NULL)
	{
		return fnfErr;
	}

	myBookName = CFBundleGetValueForInfoDictionaryKey(myApplicationBundle, CFSTR("CFBundleHelpBookName"));
	if (myBookName == NULL)
	{
		return fnfErr;
	}

	if (CFGetTypeID(myBookName) != CFStringGetTypeID())
	{
		return paramErr;
	}

	return AHGotoPage(myBookName, CF(pagePath), NULL);
}

@interface DTXApplicationDelegate () <SUUpdaterDelegate>
{
	__weak IBOutlet NSMenu *_appMenu;
	__weak IBOutlet NSMenuItem *_aboutMenuItem;
	__weak IBOutlet NSMenuItem *_hideMenuItem;
	__weak IBOutlet NSMenuItem *_quitMenuItem;
	
	__strong IBOutlet SUUpdater* _updater;
	
	DTXAboutWindowController* _aboutWindowController;
	
	DTXColorTryoutsWindowController* _colorPlaygroundController;
}

@end

@implementation DTXApplicationDelegate
{
	BOOL _hasNoDocumentWindowOpen;
	BOOL _hasAnyDocumentWindowOpen;
	BOOL _hasNewRecordingDocumentWindowOpen;
	BOOL _hasAtLeastRecordingDocumentWindowOpen;
	BOOL _hasRecordingDocumentWindowOpen;
	BOOL _hasSavedDocumentWindowOpen;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	NSString* actualName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	
	_appMenu.title = actualName;
	_aboutMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @""), actualName];
	_hideMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Hide %@", @""), actualName];
	_quitMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), actualName];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_updateFromMainWindow) name:NSWindowDidBecomeMainNotification object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_updateFromMainWindow) name:NSWindowDidResignMainNotification object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_updateFromMainWindow) name:DTXRecordingDocumentStateDidChangeNotification object:nil];
}

- (void)_updateFromMainWindow
{
	dispatch_async(dispatch_get_main_queue(), ^{
		DTXRecordingDocument* doc = [NSDocumentController.sharedDocumentController documentForWindow:NSApp.mainWindow];
		
		[self willChangeValueForKey:@"hasNoDocumentWindowOpen"];
		[self willChangeValueForKey:@"hasAnyDocumentWindowOpen"];
		[self willChangeValueForKey:@"hasNewRecordingDocumentWindowOpen"];
		[self willChangeValueForKey:@"hasAtLeastRecordingDocumentWindowOpen"];
		[self willChangeValueForKey:@"hasRecordingDocumentWindowOpen"];
		[self willChangeValueForKey:@"hasSavedDocumentWindowOpen"];
		
		_hasNoDocumentWindowOpen = doc == nil;
		_hasAnyDocumentWindowOpen = doc != nil;
		_hasNewRecordingDocumentWindowOpen = doc != nil && doc.documentState == DTXRecordingDocumentStateNew;
		_hasAtLeastRecordingDocumentWindowOpen = doc.documentState >= DTXRecordingDocumentStateLiveRecording;
		_hasRecordingDocumentWindowOpen = doc.documentState == DTXRecordingDocumentStateLiveRecording;
		_hasSavedDocumentWindowOpen = doc.documentState >= DTXRecordingDocumentStateLiveRecordingFinished;
		
		dtx_log_debug(@"hasNoDocumentWindowOpen: %@", @(_hasNoDocumentWindowOpen));
		dtx_log_debug(@"hasAnyDocumentWindowOpen: %@", @(_hasAnyDocumentWindowOpen));
		dtx_log_debug(@"hasNewRecordingDocumentWindowOpen: %@", @(_hasNewRecordingDocumentWindowOpen));
		dtx_log_debug(@"hasAtLeastRecordingDocumentWindowOpen: %@", @(_hasAtLeastRecordingDocumentWindowOpen));
		dtx_log_debug(@"hasRecordingDocumentWindowOpen: %@", @(_hasRecordingDocumentWindowOpen));
		dtx_log_debug(@"hasSavedDocumentWindowOpen: %@", @(_hasSavedDocumentWindowOpen));
		
		[self didChangeValueForKey:@"hasNoDocumentWindowOpen"];
		[self didChangeValueForKey:@"hasAnyDocumentWindowOpen"];
		[self didChangeValueForKey:@"hasNewRecordingDocumentWindowOpen"];
		[self didChangeValueForKey:@"hasAtLeastRecordingDocumentWindowOpen"];
		[self didChangeValueForKey:@"hasRecordingDocumentWindowOpen"];
		[self didChangeValueForKey:@"hasSavedDocumentWindowOpen"];
	});
}

- (IBAction)showAboutWindow:(id)sender
{
	if(_aboutWindowController != nil)
	{
		[_aboutWindowController showWindow:nil];
		return;
	}
	
	_aboutWindowController = [NSStoryboard storyboardWithName:@"About" bundle:NSBundle.mainBundle].instantiateInitialController;
	[_aboutWindowController showWindow:nil];
	[_aboutWindowController.window center];
	
	__block id observer;
	observer = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification object:_aboutWindowController.window queue:nil usingBlock:^(NSNotification * _Nonnull note) {
		
		_aboutWindowController = nil;
		
		[NSNotificationCenter.defaultCenter removeObserver:observer];
		observer = nil;
	}];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXProfilingConfigurationUseDefaultConfiguration": @YES}];
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXSelectedProfilingConfiguration_timeLimit": @2}];
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXSelectedProfilingConfiguration_timeLimitType": @1}];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"DTXProfilingConfigurationUseDefaultConfiguration"])
	{
		[DTXProfilingConfiguration.defaultProfilingConfigurationForRemoteProfiling setAsDefaultRemoteProfilingConfiguration];
	}
	
	[NSHelpManager.sharedHelpManager registerBooksInBundle:NSBundle.mainBundle];
	
	[NSTask launchedTaskWithExecutableURL:[NSURL fileURLWithPath:@"/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"] arguments:@[@"-f", NSBundle.mainBundle.bundlePath, @"-R", @"-lint"] error:NULL terminationHandler:^(NSTask * _Nonnull task) {
		if(task.terminationStatus != 0)
		{
			dtx_log_error(@"lsregister opration failed");
		}
	}];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	
}

- (IBAction)openGitHubPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/wix/DetoxInstruments"]];
}

- (IBAction)helpIntegrationGuidePage:(id)sender
{
	DTXGoToHelpPage(@"XcodeIntegrationGuide");
}

- (IBAction)helpProfilingOptions:(id)sender
{
	DTXGoToHelpPage(@"ProfilingOptions");
}

- (IBAction)helpProfilingDiscovery:(id)sender
{
	DTXGoToHelpPage(@"AppDiscovery");
}

- (IBAction)helpIgnoreCategories:(id)sender
{
	DTXGoToHelpPage(@"ProfilingOptions");
}

- (IBAction)helpAppManagement:(id)sender
{
	DTXGoToHelpPage(@"AppManagement");
}

- (IBAction)showDocumentHelp:(id)sender
{
	DTXGoToHelpPage(@"RecordingDocument");
}

- (IBAction)showDiscoveryHelp:(id)sender
{
	DTXGoToHelpPage(@"AppDiscovery");
}

- (IBAction)revealProfilerFramework:(id)sender
{
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"Contents/SharedSupport/ProfilerFramework/DTXProfiler.framework"]]];
}

- (IBAction)openIssuesPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/wix/DetoxInstruments/issues/new/choose"]];
}

- (IBAction)showColorPlayground:(id)sender
{
	if(_colorPlaygroundController != nil)
	{
		[_colorPlaygroundController showWindow:nil];
		return;
	}
	
	_colorPlaygroundController = [DTXColorTryoutsWindowController new];
	[[[NSNib alloc] initWithNibNamed:@"DTXColorTryoutsWindow" bundle:[NSBundle bundleForClass:DTXColorTryoutsWindow.class]] instantiateWithOwner:_colorPlaygroundController topLevelObjects:nil];
	
	[_colorPlaygroundController showWindow:nil];
	
	__block id observer;
	observer = [NSNotificationCenter.defaultCenter addObserverForName:NSWindowWillCloseNotification object:_colorPlaygroundController.window queue:nil usingBlock:^(NSNotification * _Nonnull note) {
		
		_colorPlaygroundController = nil;
		
		[NSNotificationCenter.defaultCenter removeObserver:observer];
		observer = nil;
	}];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSMutableArray<DTXRecordingDocument*>* recordingDocuments = [NSMutableArray new];
	
	[[NSDocumentController sharedDocumentController].documents enumerateObjectsUsingBlock:^(__kindof NSDocument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj documentState] == DTXRecordingDocumentStateLiveRecording)
		{
			[recordingDocuments addObject:obj];
		}
	}];
	
	if(recordingDocuments.count > 0)
	{
		[recordingDocuments enumerateObjectsUsingBlock:^(DTXRecordingDocument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj stopLiveRecording];
		}];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[sender terminate:nil];
		});
		
		return NSTerminateCancel;
	}
	
	return NSTerminateNow;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	dtx_log_info(@"Validating menu item: %@ (action: %@)", menuItem, NSStringFromSelector(menuItem.action));
	
	if(menuItem.action == @selector(checkForUpdates:))
	{
		BOOL canCheckForUpdates = [self updaterMayCheckForUpdates:_updater];
		menuItem.hidden = canCheckForUpdates == NO;
		
		return canCheckForUpdates;
	}
	
	if(menuItem.action == @selector(showColorPlayground:))
	{
#if ! DEBUG
		menuItem.hidden = YES;
#endif
		
		return YES;
	}
	
	if(menuItem.action == @selector(toggleShowTimelineLabels:))
	{
		menuItem.hidden = _hasAtLeastRecordingDocumentWindowOpen == NO;
		if(menuItem.hidden)
		{
			dtx_log_info(@"Hiding “Interval Labels” menu item");
			
			return NO;
		}
		
		BOOL toggled = [NSUserDefaults.standardUserDefaults boolForKey:@"DTXPlotSettingsDisplayLabels"];
		
		menuItem.title =  toggled ? NSLocalizedString(@"Hide Interval Labels", @"") : NSLocalizedString(@"Show Interval Labels", @"");
		
		return YES;
	}
	
	if(menuItem.action == @selector(_CLIIntegrationAction:) && menuItem.alternate == NO)
	{
		if(DTXApp.isShitshowVersion)
		{
			menuItem.alternate = NO;
			menuItem.hidden = YES;
			return NO;
		}
		
		NSUInteger integrationState = self._CLIInstallationStatus;
		
		BOOL isPath = [menuItem.identifier isEqualToString:@"DTXCLIMoreInfoPath"];
		if(isPath || [menuItem.identifier isEqualToString:@"DTXCLIMoreInfoLabel"])
		{
			menuItem.hidden = integrationState == 0;
			
			if(isPath)
			{
				menuItem.image = integrationState == 2 ? [NSImage imageNamed:@"warning-menu"] : nil;
				menuItem.image.size = NSMakeSize(16, 16);
				menuItem.title = self._CLIInstallURL.path;
			}
			
			return NO;
		}
		
		switch (integrationState) {
			case 0:
				menuItem.title = NSLocalizedString(@"Install Command Line Utility", @"");
				menuItem.identifier = @"_installCLIIntegration";
				break;
			case 1:
				menuItem.title = NSLocalizedString(@"Uninstall Command Line Utility", @"");
				menuItem.identifier = @"_uninstallCLIIntegration";
				break;
			case 2:
				menuItem.title = NSLocalizedString(@"Repair Command Line Utility", @"");
				menuItem.identifier = @"_installCLIIntegration";
				break;
		}
		
		return YES;
	}
	
	if(menuItem.action == @selector(_CLIIntegrationAction:) && menuItem.alternate == YES)
	{
		if(DTXApp.isShitshowVersion)
		{
			menuItem.alternate = NO;
			menuItem.hidden = YES;
			return NO;
		}
		
		NSUInteger integrationState = self._CLIInstallationStatus;
		
		menuItem.keyEquivalentModifierMask = integrationState == 0 ? 0 : NSEventModifierFlagOption;
		
		switch (integrationState) {
			case 0:
				menuItem.title = NSLocalizedString(@"Uninstall Command Line Utility", @"");
				menuItem.identifier = @"";
				return NO;
				break;
			case 1:
				menuItem.title = NSLocalizedString(@"Reinstall Command Line Utility", @"");
				menuItem.identifier = @"_installCLIIntegration";
				break;
			case 2:
				menuItem.title = NSLocalizedString(@"Uninstall Command Line Utility", @"");
				menuItem.identifier = @"_uninstallCLIIntegration";
				break;
		}
		
		return YES;
	}
	
	if(menuItem.action == @selector(_showInstrumentHelp:))
	{
		menuItem.hidden = YES;
		
		return NO;
	}
	
	if(menuItem.action == @selector(_toggleNowMode:))
	{
		menuItem.hidden = YES;
		
		return NO;
	}

	return [NSApp validateMenuItem:menuItem];;
}

- (IBAction)checkForUpdates:(id)sender
{
	[_updater checkForUpdates:sender];
}

- (IBAction)toggleShowTimelineLabels:(id)sender
{
	[NSUserDefaults.standardUserDefaults setBool:![NSUserDefaults.standardUserDefaults boolForKey:@"DTXPlotSettingsDisplayLabels"] forKey:@"DTXPlotSettingsDisplayLabels"];
}

- (NSURL*)_CLIUtilityURL
{
	static NSURL* rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = [[NSBundle.mainBundle.executableURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"dtxinst"];
	});
	
	return rv;
}

- (NSURL*)_CLIInstallURL
{
	static NSURL* rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = [NSURL fileURLWithPath:@"/usr/local/bin/dtxinst"];
	});
	
	return rv;
}

- (NSUInteger)_CLIInstallationStatus
{
//	DTXStartTimeMeasurment();
//	dtx_defer {
//		DTXEndTimeMeasurment("determine installation status");
//	};
	
	NSURL* CLIInstallURL = self._CLIInstallURL;
	
	if([NSFileManager.defaultManager fileExistsAtPath:CLIInstallURL.path] == NO)
	{
		return 0;
	}
	
	NSURL* CLIUtilityURL = self._CLIUtilityURL;
	if([CLIInstallURL.URLByResolvingSymlinksInPath isEqual:CLIUtilityURL] == NO)
	{
		return 2;
	}
	
	return 1;
}

- (void)_uninstallAndPresentError:(BOOL)presentError
{
	NSError* error;
	if([NSFileManager.defaultManager removeItemAtURL:self._CLIInstallURL error:&error] == NO && presentError)
	{
		[NSApp presentError:error];
	}
}

- (void)_installCLIIntegration
{
	NSError* error;
	
	[self _uninstallAndPresentError:NO];
	if([NSFileManager.defaultManager createSymbolicLinkAtURL:self._CLIInstallURL withDestinationURL:self._CLIUtilityURL error:&error] == NO)
	{
		[NSApp presentError:error];
	}
}

- (void)_uninstallCLIIntegration
{
	[self _uninstallAndPresentError:YES];
}

- (IBAction)_CLIIntegrationAction:(NSMenuItem*)sender
{
	SEL selector = NSSelectorFromString(sender.identifier);
	[self performSelector:selector];
}

#pragma mark SUUpdaterDelegate

- (BOOL)updaterMayCheckForUpdates:(SUUpdater *)updater
{
	return DTXApp.isShitshowVersion == NO;
}

#pragma mark Empty Menu Selectors

- (IBAction)_showInstrumentHelp:(id)sender
{
}

- (IBAction)_toggleNowMode:(NSControl*)sender
{
}

@end
