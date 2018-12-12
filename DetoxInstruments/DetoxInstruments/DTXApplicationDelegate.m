//
//  AppDelegate.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXApplicationDelegate.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "DTXRecordingDocument.h"
#import "DTXAboutWindowController.h"
#import "DTXColorTryoutsWindow.h"

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

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	NSString* actualName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	
	_appMenu.title = actualName;
	_aboutMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @""), actualName];
	_hideMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Hide %@", @""), actualName];
	_quitMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), actualName];
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

- (void)verifyLldbInitIsNotBroken
{
	
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
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	[self verifyLldbInitIsNotBroken];
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

- (IBAction)revealProfilerFramework:(id)sender
{
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"Contents/SharedSupport/ProfilerFramework/DTXProfiler.framework"]]];
}

- (IBAction)openIssuesPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/wix/DetoxInstruments/issues"]];
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
	if(menuItem.action == @selector(checkForUpdates:))
	{
		BOOL canCheckForUpdates = [self updaterMayCheckForUpdates:_updater];
		menuItem.hidden = canCheckForUpdates == NO;
		
		return canCheckForUpdates;
	}
	
	if(menuItem.action == @selector(showColorPlayground:))
	{
#ifndef DEBUG
		menuItem.hidden = YES;
#endif
		
		return YES;
	}

	return [NSApp validateMenuItem:menuItem];;
}

- (IBAction)checkForUpdates:(id)sender
{
	[_updater checkForUpdates:sender];
}

#pragma mark SUUpdaterDelegate

- (BOOL)updaterMayCheckForUpdates:(SUUpdater *)updater
{
	return [NSBundle.mainBundle.bundlePath containsString:@"node_modules/"] == NO;
}

@end
