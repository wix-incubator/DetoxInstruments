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

@interface DTXApplicationDelegate ()
{
//	CCNPreferencesWindowController* _preferencesWindowController;
}

@end

@implementation DTXApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"DTXProfilingConfigurationUseDefaultConfiguration"])
	{
		[DTXProfilingConfiguration.defaultProfilingConfigurationForRemoteProfiling setAsDefaultRemoteProfilingConfiguration];
	}
	
	// Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Insert code here to tear down your application
}

- (IBAction)openGitHubPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/wix/DetoxInstruments"]];
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
