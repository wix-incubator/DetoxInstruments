//
//  DTXLogDetailController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXLogDetailController.h"
#import "DTXLogDataProvider.h"

@implementation DTXLogDetailController
{
	IBOutlet NSTableView* _tableView;
	
	NSImage* _consoleAppImage;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSString* path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.Console"];
	_consoleAppImage = [[NSWorkspace sharedWorkspace] iconForFile:path] ?: [NSImage imageNamed:@"console_small"];
	_consoleAppImage.size = NSMakeSize(16, 16);
}

- (BOOL)canCopy
{
	return YES;
}

- (void)loadProviderWithDocument:(DTXRecordingDocument*)document
{
	[self view];
	
	self.detailDataProvider = (id)[[DTXLogDataProvider alloc] initWithDocument:document];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[(DTXLogDataProvider*)self.detailDataProvider setManagedTableView:_tableView];
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
	[(DTXLogDataProvider*)self.detailDataProvider setManagedTableView:nil];
}

- (void)updateViewWithInsets:(NSEdgeInsets)insets
{
	_tableView.enclosingScrollView.contentInsets = insets;
}

- (void)scrollToTimestamp:(NSDate *)timestamp
{
	[(DTXLogDataProvider*)self.detailDataProvider scrollToTimestamp:timestamp];
}

- (NSView *)viewForCopy
{
	return _tableView;
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Console", @"");
}

- (NSImage *)smallDisplayIcon
{
	return _consoleAppImage;
}

@end
