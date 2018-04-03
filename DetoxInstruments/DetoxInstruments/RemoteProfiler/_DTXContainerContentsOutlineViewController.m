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
}

@end

@implementation _DTXContainerContentsOutlineViewController

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
//	[_outlineView expandItem:nil expandChildren:YES];
}

- (void)showSaveDialogWithCompletionHandler:(void(^)(NSURL* saveLocation))completionHandler
{
	NSSavePanel* savePanel = [NSSavePanel savePanel];
	
	NSString* zipName = [NSString stringWithFormat:@"%@.zip", self.profilingTarget.appName];
	
	savePanel.nameFieldStringValue = zipName;
	savePanel.contentView.wantsLayer = YES;
	
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:^ (NSInteger result) {
		NSURL* URL;
		if (result == NSModalResponseOK)
		{
			URL = [savePanel URL];
		}
		
		completionHandler(URL);
	}];
}

- (IBAction)_downloadContainer:(id)sender
{
	[self.profilingTarget downloadContainer];
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	if(item == nil)
	{
		return self.profilingTarget.containerContents.children.count;
	}
	
	return ((DTXFileSystemItem*)item).children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	DTXFileSystemItem* fsItem = item;
	if(fsItem == nil)
	{
		fsItem = self.profilingTarget.containerContents;
	}
	
	return [fsItem.children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	DTXFileSystemItem* fsItem = item;
	
	return fsItem.isDirectory == YES && fsItem.children.count > 0;
}

#pragma mark NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	DTXFileSystemItem* fsItem = item;
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXFileItemCellView" owner:nil];
	
	cellView.textField.stringValue = fsItem.name;
	
	NSImage* icon;
	
	if(fsItem.isDirectory)
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
	cellView.toolTip = fsItem.name;
	
	return cellView;
}

@end

