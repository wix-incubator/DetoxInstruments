//
//  _DTXContainerContentsOutlineViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/1/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "_DTXContainerContentsOutlineViewController.h"

@interface _DTXContainerContentsOutlineViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	IBOutlet NSOutlineView* _outlineView;
	IBOutlet NSButton* _defaultButton;
	
	DTXFileSystemItem* _currentlyBeingSaved;
}

@end

@implementation _DTXContainerContentsOutlineViewController

- (NSArray<NSButton *> *)actionButtons
{
	return @[];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSString* format;
	DTXFileSystemItem* item = [_outlineView itemAtRow:_outlineView.clickedRow];
	BOOL isRoot = item == self.profilingTarget.containerContents;
	
	if(menuItem.action == @selector(_downloadContainer:))
	{
		format = NSLocalizedString(@"Download “%@”", @"");
	}
	
	if(menuItem.action == @selector(_deleteItem:))
	{
		format = NSLocalizedString(@"Delete “%@”", @"");
	}
	
	menuItem.title = [NSString stringWithFormat:format, isRoot ? self.profilingTarget.appName : item.name];
	
	if(isRoot && menuItem.action == @selector(_deleteItem:))
	{
		return NO;
	}
	
	return YES;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_outlineView.indentationPerLevel = 15;
	
	self.view.wantsLayer = YES;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[_outlineView.window makeFirstResponder:_outlineView];
}

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	[self.profilingTarget loadContainerContents];
}

- (void)reloadContainerContents
{
	if(_profilingTarget == nil)
	{
		return;
	}
	
	[_outlineView reloadData];
	[_outlineView expandItem:nil expandChildren:YES];
}

- (void)showSaveDialogWithCompletionHandler:(void(^)(NSURL* saveLocation))completionHandler
{
	BOOL isDirectoryForUI = _currentlyBeingSaved.isDirectoryForUI;
	BOOL isDirectoryActual = _currentlyBeingSaved.isDirectory;
	NSString* fileName = _currentlyBeingSaved.name;
	if(_currentlyBeingSaved == self.profilingTarget.containerContents)
	{
		fileName = self.profilingTarget.appName;
	}
	
	NSSavePanel* savePanel;
	
	if(isDirectoryForUI == YES)
	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = [NSString stringWithFormat:NSLocalizedString(@"Existing “%@” directory will be overwritten if it exists.", @""), fileName];
		
		savePanel = openPanel;
	}
	else
	{
		savePanel = [NSSavePanel savePanel];
	}

	savePanel.nameFieldStringValue = fileName;
	savePanel.canCreateDirectories = YES;
	savePanel.contentView.wantsLayer = YES;
	
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:^ (NSInteger result) {
		NSURL* URL;
		if (result == NSModalResponseOK)
		{
			URL = [savePanel URL];
		}
		
		if(_currentlyBeingSaved.isDirectoryForUI)
		{
			URL = [URL URLByAppendingPathComponent:fileName];
		}
		
		if([URL checkResourceIsReachableAndReturnError:NULL] == YES)
		{
			[[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
		}
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			completionHandler(URL);
		});
	}];
}

- (IBAction)_downloadContainer:(id)sender
{
	_currentlyBeingSaved = [_outlineView itemAtRow:_outlineView.clickedRow];
	
	[self.profilingTarget downloadContainerAtURL:_currentlyBeingSaved.URL];
}

- (void)deleteItemAtRow:(NSInteger)row
{
	_currentlyBeingSaved = [_outlineView itemAtRow:row];
	
	NSAlert* alert = [NSAlert new];
	alert.alertStyle = NSAlertStyleWarning;
	alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete “%@”?", @""), _currentlyBeingSaved.name];
	alert.informativeText = NSLocalizedString(@"This item will be deleted immediately. You can’t undo this action.", @"");
	[alert addButtonWithTitle:NSLocalizedString(@"Delete", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
	
	[alert beginSheetModalForWindow:_outlineView.window completionHandler:^(NSModalResponse returnCode) {
		if(returnCode == NSAlertSecondButtonReturn)
		{
			return;
		}
		
		[self.profilingTarget deleteContainerItemAtURL:_currentlyBeingSaved.URL];
		[self.profilingTarget loadContainerContents];
	}];
}

- (IBAction)_deleteItem:(id)sender
{
	[self deleteItemAtRow:_outlineView.clickedRow];
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	if(item == nil)
	{
//		return self.profilingTarget.containerContents.children.count;
		return 1;
	}
	
	return ((DTXFileSystemItem*)item).children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	DTXFileSystemItem* fsItem = item;
	if(fsItem == nil)
	{
		return self.profilingTarget.containerContents;
	}
	
	return [fsItem.children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	DTXFileSystemItem* fsItem = item;
	
	return fsItem.isDirectoryForUI == YES && fsItem.children.count > 0;
}

#pragma mark NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	DTXFileSystemItem* fsItem = item;
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXFileItemCellView" owner:nil];
	
	NSString* itemName = fsItem.name;
	if(fsItem == self.profilingTarget.containerContents)
	{
		itemName = self.profilingTarget.appName;
	}
	
	cellView.textField.stringValue = itemName;
	
	NSImage* icon;
	
	if(fsItem == self.profilingTarget.containerContents)
	{
		icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
	}
	else if(fsItem.isDirectoryForUI)
	{
		icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
	}
	else
	{
		CFStringRef fileExtension = (__bridge CFStringRef)[fsItem.name pathExtension];
		NSString* fileUTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL));
		icon = [[NSWorkspace sharedWorkspace] iconForFileType:fileUTI];
	}
	
	icon.size = NSMakeSize(16, 16);
	
	cellView.imageView.image = icon;
	cellView.toolTip = itemName;
	
	return cellView;
}

@end

