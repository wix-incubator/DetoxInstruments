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
//#import "CCNPreferencesWindowController.h"

@import Sparkle;

static NSString* const __lldbInitMagic = @"";

@interface DTXApplicationDelegate () <SUUpdaterDelegate>
{
//	CCNPreferencesWindowController* _preferencesWindowController;
	
	__weak IBOutlet NSMenu *_appMenu;
	__weak IBOutlet NSMenuItem *_aboutMenuItem;
	__weak IBOutlet NSMenuItem *_hideMenuItem;
	__weak IBOutlet NSMenuItem *_quitMenuItem;
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
