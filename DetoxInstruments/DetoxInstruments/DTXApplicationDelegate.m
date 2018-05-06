//
//  AppDelegate.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXApplicationDelegate.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "DTXDocument.h"
#import "DTXAboutWindowController.h"
//#import "CCNPreferencesWindowController.h"

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
	
	return AHGotoPage(myBookName, (__bridge CFStringRef)pagePath, NULL);
}

@interface DTXApplicationDelegate () <SUUpdaterDelegate>
{
//	CCNPreferencesWindowController* _preferencesWindowController;
	
	__weak IBOutlet NSMenu *_appMenu;
	__weak IBOutlet NSMenuItem *_aboutMenuItem;
	__weak IBOutlet NSMenuItem *_hideMenuItem;
	__weak IBOutlet NSMenuItem *_quitMenuItem;
	
	DTXAboutWindowController* _aboutWindowController;
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
	
	_aboutWindowController = [NSStoryboard storyboardWithName:@"About" bundle:NSBundle.mainBundle].instantiateInitialController;
}

- (IBAction)showAboutWindow:(id)sender
{
	if(_aboutWindowController.window.isVisible)
	{
		[_aboutWindowController.window orderFrontRegardless];
		return;
	}
	
	[_aboutWindowController showWindow:nil];
	[_aboutWindowController.window center];
}

- (void)verifyLldbInitIsNotBroken
{
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DTXProfilingConfigurationUseDefaultConfiguration": @YES}];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"DTXProfilingConfigurationUseDefaultConfiguration"])
	{
		[DTXProfilingConfiguration.defaultProfilingConfigurationForRemoteProfiling setAsDefaultRemoteProfilingConfiguration];
	}
	
	AHRegisterHelpBookWithURL((__bridge CFURLRef)NSBundle.mainBundle.bundleURL);
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

- (IBAction)revealProfilerFramework:(id)sender
{
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"Contents/SharedSupport/ProfilerFramework/DTXProfiler.framework"]]];
}

- (IBAction)openIssuesPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/wix/DetoxInstruments/issues"]];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSMutableArray<DTXDocument*>* recordingDocuments = [NSMutableArray new];
	
	[[NSDocumentController sharedDocumentController].documents enumerateObjectsUsingBlock:^(__kindof NSDocument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj documentState] == DTXDocumentStateLiveRecording)
		{
			[recordingDocuments addObject:obj];
		}
	}];
	
	if(recordingDocuments.count > 0)
	{
		[recordingDocuments enumerateObjectsUsingBlock:^(DTXDocument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj stopLiveRecording];
		}];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[sender terminate:nil];
		});
		
		return NSTerminateCancel;
	}
	
//	if(recordingDocuments.count > 0)
//	{
//		NSAlert* alert = [NSAlert new];
//		alert.alertStyle = NSAlertStyleCritical;
//		alert.messageText = [NSString localizedStringWithFormat:NSLocalizedString(@"There are %d recordings in progress.", @""), recordingDocuments.count];
//		alert.informativeText = NSLocalizedString(@"Quitting will abort any ongoing recordings.", @"");
//		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
//		[alert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
//
//		[alert beginSheetModalForWindow:sender.keyWindow completionHandler:^(NSModalResponse returnCode) {
//			[sender replyToApplicationShouldTerminate:returnCode == NSAlertSecondButtonReturn];
//		}];
//
//		return NSTerminateLater;
//	}
	
	return NSTerminateNow;
}

@end
