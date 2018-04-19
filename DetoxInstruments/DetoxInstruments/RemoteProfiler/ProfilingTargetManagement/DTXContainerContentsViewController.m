//
//  DTXContainerContentsViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/1/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXContainerContentsViewController.h"
#import "DTXZipper.h"
#import "SSZipArchive.h"
#import "DTXTwoLabelsCellView.h"

@interface DTXContainerContentsViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	IBOutlet NSOutlineView* _outlineView;
	
	IBOutlet NSMenu* _menu;
	IBOutlet NSButton* _helpButton;
	IBOutlet NSButton* _refreshButton;
	
	DTXFileSystemItem* _currentlyBeingSaved;
	
	NSInteger _progressIndicatorCounter;
	NSViewController* _modalProgressIndicatorController;
	
	NSByteCountFormatter* _sizeFormatter;
}

@end

@implementation DTXContainerContentsViewController

@synthesize profilingTarget=_profilingTarget;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSInteger row = _outlineView.clickedRow;
	if(row == -1)
	{
		row = _outlineView.selectedRow;
	}
	if(row == -1)
	{
		return NO;
	}
	
	DTXFileSystemItem* item = [_outlineView itemAtRow:row];
	BOOL isRoot = [item isEqualToFileSystemItem:self.profilingTarget.containerContents];
	
	if(isRoot && menuItem.action == @selector(delete:))
	{
		return NO;
	}
	
	return YES;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_outlineView.indentationPerLevel = 15;
	[_outlineView registerForDraggedTypes:[NSArray arrayWithObject:(NSString*)kUTTypeFileURL]];
	
	self.view.wantsLayer = YES;
	
	_modalProgressIndicatorController = [self.storyboard instantiateControllerWithIdentifier:@"ModalProgressIndicator"];
	
	_sizeFormatter = [NSByteCountFormatter new];
	_sizeFormatter.countStyle = NSByteCountFormatterCountStyleFile;
	_sizeFormatter.allowsNonnumericFormatting = NO;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[_outlineView.window makeFirstResponder:_outlineView];
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
	[_modalProgressIndicatorController dismissController:nil];
}

- (void)viewDidLayout
{
	[super viewDidLayout];
	
	_outlineView.outlineTableColumn.maxWidth = _outlineView.enclosingScrollView.bounds.size.width - 2;
	_outlineView.outlineTableColumn.width = _outlineView.enclosingScrollView.bounds.size.width - 2;
	[_outlineView tile];
	[_outlineView setNeedsLayout:YES];
	[_outlineView layoutSubtreeIfNeeded];
}

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	if(profilingTarget == nil)
	{
		return;
	}
	
	[self.profilingTarget loadContainerContents];
	[self increaseProgressIndicatorCounterAndDisplayRightAway:NO];
}

- (void)noteProfilingTargetDidLoadServiceData
{
	if(self.profilingTarget == nil)
	{
		return;
	}
	
	[self decreaseProgressIndicatorCounter];
	
	DTXFileSystemItem* selectedItem = [_outlineView itemAtRow:_outlineView.selectedRow];
	
	[_outlineView reloadItem:nil reloadChildren:YES];
	
	[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_outlineView rowForItem:selectedItem]] byExtendingSelection:NO];
}

- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped
{
	[self decreaseProgressIndicatorCounter];
	
	BOOL isDirectoryForUI = _currentlyBeingSaved.isDirectoryForUI;
//	BOOL isDirectoryActual = _currentlyBeingSaved.isDirectory;
	NSString* fileName = _currentlyBeingSaved.name;
	if([_currentlyBeingSaved isEqualToFileSystemItem:self.profilingTarget.containerContents])
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
			if(URL == nil)
			{
				return;
			}
			
			if(wasZipped)
			{
				NSURL* tempZipURL = DTXTempZipURL();
				[data writeToURL:tempZipURL atomically:YES];
				
				[SSZipArchive unzipFileAtPath:tempZipURL.path toDestination:URL.path];
				
				[[NSFileManager defaultManager] removeItemAtURL:tempZipURL error:NULL];
			}
			else
			{
				[data writeToURL:URL atomically:YES];
			}
			
			[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[URL]];
		});
	}];
}

- (IBAction)refresh:(id)sender
{
	[self.profilingTarget loadContainerContents];
	
	[self increaseProgressIndicatorCounterAndDisplayRightAway:NO];
}

- (IBAction)downloadSelectedItems:(id)sender
{
	_currentlyBeingSaved = [_outlineView itemAtRow:_outlineView.clickedRow];
	
	[self.profilingTarget downloadContainerAtURL:_currentlyBeingSaved.URL];
	
	[self increaseProgressIndicatorCounterAndDisplayRightAway:YES];
}

- (void)deleteItemAtRow:(NSInteger)row
{
	if(row == -1)
	{
		NSBeep();
		return;
	}
	
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
		[self increaseProgressIndicatorCounterAndDisplayRightAway:NO];
	}];
}

- (IBAction)delete:(id)sender
{
	[self deleteItemAtRow:_outlineView.clickedRow != -1 ? _outlineView.clickedRow : _outlineView.selectedRow];
}

- (void)increaseProgressIndicatorCounterAndDisplayRightAway:(BOOL)rightAway
{
	_progressIndicatorCounter += 1;
	
//	NSLog(@"💔 %@\n%@", @(_progressIndicatorCounter), NSThread.callStackSymbols);
	
	void (^display)(void) = ^{
		if(_progressIndicatorCounter > 0)
		{
			if(self.view.window == nil || [self.presentedViewControllers containsObject:_modalProgressIndicatorController])
			{
				return;
			}
			
//			NSLog(@"🤦‍♂️ %@", @(_progressIndicatorCounter));
			
			[self presentViewControllerAsSheet:_modalProgressIndicatorController];
			_modalProgressIndicatorController.view.window.styleMask &= ~NSWindowStyleMaskResizable;
		}
	};
	
	if(rightAway)
	{
		display();
	}
	else
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), display);
	}
}

- (void)decreaseProgressIndicatorCounter
{
	_progressIndicatorCounter = MAX(_progressIndicatorCounter - 1, 0);
	
//	NSLog(@"❤️ %@", @(_progressIndicatorCounter));
	
	if(_progressIndicatorCounter == 0)
	{
		[_modalProgressIndicatorController dismissController:nil];
	}
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	if(item == nil)
	{
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
	
	return fsItem.isDirectoryForUI == YES;
}

#pragma mark NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	DTXFileSystemItem* fsItem = item;
	
	DTXTwoLabelsCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXFileItemCellView" owner:nil];
	
	NSString* itemName = fsItem.name;
	if([fsItem isEqualToFileSystemItem:self.profilingTarget.containerContents])
	{
		itemName = self.profilingTarget.appName;
	}
	
	cellView.textField.stringValue = itemName;
	cellView.detailTextField.stringValue = [_sizeFormatter stringFromByteCount:fsItem.size.unsignedLongLongValue];
	
	NSImage* icon;
	
	if([fsItem isEqualToFileSystemItem:self.profilingTarget.containerContents])
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

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	if(item == nil)
	{
		return NSDragOperationNone;
	}
	
	DTXFileSystemItem* fsItem = item;
	
	if(fsItem.isDirectoryForUI == NO)
	{
		return NSDragOperationNone;
	}
	
	return NSDragOperationCopy;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(nullable id)item childIndex:(NSInteger)index
{
	DTXFileSystemItem* fsItem = item;
	
	NSArray<NSURL*>* draggedFileURLs = [[info draggingPasteboard] readObjectsForClasses:@[[NSURL class]] options:nil];
	
	NSAlert* alert = [NSAlert new];
	alert.alertStyle = NSAlertStyleWarning;
	if(draggedFileURLs.count == 1)
	{
		alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Send “%@” to “%@”?", @""), draggedFileURLs.firstObject.lastPathComponent, fsItem.name];
		alert.informativeText = NSLocalizedString(@"Existing item with the same name will be overwritten.", @"");
	}
	else
	{
		alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Send %lu items to “%@”?", @""), draggedFileURLs.count, fsItem.name];
		alert.informativeText = NSLocalizedString(@"Existing items with the same name will be overwritten.", @"");
	}
	[alert addButtonWithTitle:NSLocalizedString(@"Send", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
	
	[alert beginSheetModalForWindow:_outlineView.window completionHandler:^(NSModalResponse returnCode) {
		if(returnCode == NSAlertSecondButtonReturn)
		{
			return;
		}
		
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
			NSURL* targetURL = fsItem.URL;
			
			NSNumber* isFirstItemDirectory;
			[draggedFileURLs.firstObject getResourceValue:&isFirstItemDirectory forKey:NSURLIsDirectoryKey error:nil];
			if(draggedFileURLs.count == 1 && isFirstItemDirectory == NO)
			{
				targetURL = [targetURL URLByAppendingPathComponent:draggedFileURLs.firstObject.pathExtension];
				[self.profilingTarget putContainerItemAtURL:targetURL data:[NSData dataWithContentsOfURL:draggedFileURLs.firstObject] wasZipped:NO];
			}
			else
			{
				NSURL* tempFileURL = DTXTempZipURL();
				BOOL zipWasSuccessful = DTXWriteZipFileWithURLArray(tempFileURL, draggedFileURLs);
				if(zipWasSuccessful)
				{
					NSData* data = [NSData dataWithContentsOfURL:tempFileURL options:NSDataReadingMappedAlways error:NULL];
					[[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:NULL];
					
					[self.profilingTarget putContainerItemAtURL:targetURL data:data wasZipped:YES];
				}
			}
			
			[self.profilingTarget loadContainerContents];
		});
		
		[self increaseProgressIndicatorCounterAndDisplayRightAway:YES];
	}];
	
	return YES;
}

#pragma mark CCNPreferencesWindowControllerProtocol

- (NSImage *)preferenceIcon
{
	NSImage* image = [NSImage imageNamed:NSImageNameFolder];
	image.size = NSMakeSize(32, 32);
	
	return image;
}

- (NSString *)preferenceIdentifier
{
	return @"ContainerContents";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"Container Files", @"");
}

@end

