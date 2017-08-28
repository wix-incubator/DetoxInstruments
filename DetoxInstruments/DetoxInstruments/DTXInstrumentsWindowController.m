//
//  DTXInstrumentsWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInstrumentsWindowController.h"
#import "DTXMainBottomPaneSplitViewController.h"
#import "DTXBottomInspectorSplitViewController.h"
#import "DTXMainContentController.h"
#import "DTXBottomContentController.h"
#import "DTXRightInspectorController.h"
#import "DTXDocument.h"
#import <CoreServices/CoreServices.h>
#import "DTXRecording+UIExtensions.h"

static NSString* const __DTXBottomPaneCollapsed = @"DTXBottomPaneCollapsed";
static NSString* const __DTXRightInspectorCollapsed = @"DTXRightInspectorCollapsed";

@interface DTXInstrumentsWindowController () <DTXMainContentControllerDelegate, DTXBottomContentControllerDelegate>
{
	__weak IBOutlet NSSegmentedControl* _layoutSegmentControl;
	
	__weak IBOutlet NSButton* _titleLabelContainer;
	NSTextField* _titleTextField;
	
	__weak IBOutlet NSButton* _stopRecordingButton;
	__weak IBOutlet NSButton* _flagButton;
	__weak IBOutlet NSButton* _pushGroupButton;
	__weak IBOutlet NSButton* _popGroupButton;
	
	DTXMainBottomPaneSplitViewController* _bottomSplitViewController;
	DTXBottomInspectorSplitViewController* _rightSplitViewController;
	
	DTXMainContentController* _mainContentController;
	DTXBottomContentController* _bottomContentController;
	DTXRightInspectorController* _inspectorContentController;
	
	BOOL _bottomCollapsed;
	BOOL _rightCollapsed;
	
	NSSavePanel* _exportPanel;
	IBOutlet NSView* _exportPanelOptions;
	IBOutlet NSPopUpButton* _formatPopupButton;
}

@end

@implementation DTXInstrumentsWindowController

- (void)dealloc
{
	[_bottomSplitViewController.splitViewItems.lastObject removeObserver:self forKeyPath:@"collapsed"];
	[_rightSplitViewController.splitViewItems.lastObject removeObserver:self forKeyPath:@"collapsed"];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[_exportPanelOptions.heightAnchor constraintEqualToConstant:65].active = YES;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
//	self.window.titleVisibility = NSWindowTitleHidden;
	
	[self.window center];
	
	_bottomSplitViewController = (id)self.window.contentViewController;
	_rightSplitViewController = (id)self.window.contentViewController.childViewControllers.lastObject;
	
	_bottomCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:__DTXBottomPaneCollapsed];
	_rightCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:__DTXRightInspectorCollapsed];
	
	_mainContentController = (id)_bottomSplitViewController.splitViewItems.firstObject.viewController;
	_bottomContentController = (id)_rightSplitViewController.splitViewItems.firstObject.viewController;
	_inspectorContentController = (id)_rightSplitViewController.splitViewItems.lastObject.viewController;
	
	[_bottomSplitViewController.splitViewItems.lastObject addObserver:self forKeyPath:@"collapsed" options:NSKeyValueObservingOptionNew context:NULL];
	[_rightSplitViewController.splitViewItems.lastObject addObserver:self forKeyPath:@"collapsed" options:NSKeyValueObservingOptionNew context:NULL];
	
	_mainContentController.delegate = self;
	_bottomContentController.delegate = self;
	
	[self _fixUpSegments];
	[self _fixUpSplitViewsAnimated:NO];
	
	self.window.contentView.wantsLayer = YES;
	self.window.contentView.canDrawSubviewsIntoLayer = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	_bottomCollapsed = _bottomSplitViewController.splitViewItems.lastObject.isCollapsed;
	_rightCollapsed = _rightSplitViewController.splitViewItems.lastObject.isCollapsed;
	
	[self _fixUpSegments];
	[self _fixUpSplitViewsAnimated:NO];
	
	[[NSUserDefaults standardUserDefaults] setBool:_bottomCollapsed forKey:__DTXBottomPaneCollapsed];
	[[NSUserDefaults standardUserDefaults] setBool:_rightCollapsed forKey:__DTXRightInspectorCollapsed];
}

- (void)setDocument:(DTXDocument*)document
{
	if(self.document != nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:DTXDocumentStateDidChangeNotification object:self.document];
	}
	
	[super setDocument:document];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXDocumentStateDidChangeNotification object:self.document];
	
	[self _fixUpRecordingButtons];
	
	_mainContentController.document = self.document;
	_bottomContentController.document = self.document;
	_inspectorContentController.document = self.document;
	
	if(_titleTextField == nil)
	{
		_titleTextField = [[NSTextField alloc] initWithFrame:_titleLabelContainer.bounds];
		[_titleLabelContainer addSubview:_titleTextField];
		_titleTextField.translatesAutoresizingMaskIntoConstraints = NO;
		[NSLayoutConstraint activateConstraints:@[[_titleLabelContainer.centerXAnchor constraintEqualToAnchor:_titleTextField.centerXAnchor],
												  [_titleLabelContainer.centerYAnchor constraintEqualToAnchor:_titleTextField.centerYAnchor],
												  [_titleTextField.widthAnchor constraintLessThanOrEqualToConstant:_titleLabelContainer.bounds.size.width - 10]]];
		
		_titleTextField.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
		_titleTextField.textColor = [NSColor darkGrayColor];
		_titleTextField.alignment = NSTextAlignmentCenter;
		_titleTextField.editable = NO;
		_titleTextField.selectable = NO;
		_titleTextField.allowsDefaultTighteningForTruncation = YES;
		_titleTextField.lineBreakMode = NSLineBreakByTruncatingHead;
		_titleTextField.usesSingleLineMode = YES;
		_titleTextField.bezeled = NO;
		_titleTextField.backgroundColor = nil;
	}
	
	[self _fixUpTitle];
	
	self.window.restorable = [(DTXDocument*)self.document documentState] >= DTXDocumentStateLiveRecordingFinished;
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	[self _fixUpRecordingButtons];
	[self _fixUpTitle];
	
	self.window.restorable = [(DTXDocument*)self.document documentState] >= DTXDocumentStateLiveRecordingFinished;
}

- (void)_fixUpTitle
{
	if(self.document != nil)
	{
		NSDateComponentsFormatter* ivFormatter = [NSDateComponentsFormatter new];
		ivFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
		
		DTXDocument* document = (DTXDocument*)self.document;
		
		if(document.documentState >= DTXDocumentStateLiveRecordingFinished && document.recording.startTimestamp && document.recording.endTimestamp)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", document.recording.appName, [ivFormatter stringFromDate:document.recording.startTimestamp toDate:document.recording.endTimestamp]];
		}
		else if(document.documentState == DTXDocumentStateLiveRecording)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", document.recording.appName, NSLocalizedString(@"Recording...", @"")];
		}
		else
		{
			_titleTextField.stringValue = NSLocalizedString(@"———", @"");
		}
	}
	else
	{
		_titleTextField.stringValue = @"";
	}
}

- (void)_fixUpRecordingButtons
{
	_stopRecordingButton.enabled =  _stopRecordingButton.alphaValue = [(DTXDocument*)self.document documentState] == DTXDocumentStateLiveRecording;
	_flagButton.enabled = _flagButton.alphaValue = [(DTXDocument*)self.document documentState] == DTXDocumentStateLiveRecording;
	_pushGroupButton.enabled = _pushGroupButton.alphaValue = 0.0; //[(DTXDocument*)self.document documentState] == DTXDocumentStateLiveRecording;
	_popGroupButton.enabled = _popGroupButton.alphaValue = 0.0; //[(DTXDocument*)self.document documentState] == DTXDocumentStateLiveRecording;
}

- (IBAction)_stopRecordingButtonPressed:(id)sender
{
	[(DTXDocument*)self.document stopLiveRecording];
}

- (IBAction)_flagButtonPressed:(id)sender
{
	[(DTXDocument*)self.document addTag];
}

- (IBAction)_pushGroupButtonPressed:(id)sender
{
	[(DTXDocument*)self.document pushGroup];
}

- (IBAction)_popGroupButtonPressed:(id)sender
{
	[(DTXDocument*)self.document popGroup];
}

- (void)_fixUpSegments
{
	[_layoutSegmentControl setSelected:!_bottomCollapsed forSegment:0];
	[_layoutSegmentControl setSelected:_bottomCollapsed ? NO : !_rightCollapsed forSegment:1];
}

- (void)_fixUpSplitViewsAnimated:(BOOL)animated
{
	NSSplitViewItem* bottomSplitViewItem = _bottomSplitViewController.splitViewItems.lastObject;
	NSSplitViewItem* rightSplitViewItem = _rightSplitViewController.splitViewItems.lastObject;
	if(animated)
	{
		bottomSplitViewItem = bottomSplitViewItem.animator;
		rightSplitViewItem = rightSplitViewItem.animator;
	}
	
	bottomSplitViewItem.collapsed = _bottomCollapsed;
	rightSplitViewItem.collapsed = _rightCollapsed;
}

- (IBAction)toggleRight:(id)sender
{
	if(_bottomCollapsed)
	{
		_rightCollapsed = NO;
		[self _fixUpSplitViewsAnimated:NO];
		_bottomCollapsed = NO;
	}
	else
	{
		_rightCollapsed = !_rightCollapsed;
	}
	
	[self _fixUpSegments];
	[self _fixUpSplitViewsAnimated:YES];
}

- (IBAction)toggleBottom:(id)sender
{
	_bottomCollapsed = !_bottomCollapsed;
	
	[self _fixUpSegments];
	[self _fixUpSplitViewsAnimated:YES];
}

- (IBAction)segmentCellAction:(NSSegmentedCell*)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	
	switch(selectedSegment)
	{
		case 0:
			[self toggleBottom:nil];
			break;
		case 1:
			[self toggleRight:nil];
			break;
	}
}

- (void)contentController:(DTXMainContentController*)cc updateUIWithUIProvider:(DTXUIDataProvider*)dataProvider;
{
	_bottomContentController.managingDataProvider = dataProvider;
	_inspectorContentController.moreInfoDataProvider = nil;
}

- (void)bottomController:(DTXBottomContentController*)bc updateWithInspectorProvider:(DTXInspectorDataProvider*)inspectorProvider
{
	_inspectorContentController.moreInfoDataProvider = inspectorProvider;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(copy:))
	{
		return self.targetForCopy && self.handlerForCopy != nil && self.handlerForCopy.canCopy;
	}
	
	if(menuItem.action == @selector(_export:))
	{
		return ((DTXDocument*)self.document).documentState >= DTXDocumentStateSavedToDisk;
	}
	
	return menuItem.action == @selector(toggleBottom:) || menuItem.action == @selector(selectExtendedDetail:) || menuItem.action == @selector(selectProfilingInfo:);
}

- (IBAction)copy:(id)sender
{
	[self.handlerForCopy copy:sender targetView:self.targetForCopy];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
	if([self.document documentState] == DTXDocumentStateNew)
	{
		return;
	}
	
	[super encodeRestorableStateWithCoder:coder];
}

- (void)setHandlerForCopy:(id<DTXWindowWideCopyHanler>)handlerForCopy
{
	_handlerForCopy = handlerForCopy;
}

- (IBAction)selectExtendedDetail:(id)sender
{
	[_inspectorContentController selectExtendedDetail];
}

- (IBAction)selectProfilingInfo:(id)sender
{
	[_inspectorContentController selectProfilingInfo];
}

- (IBAction)_exportFormatChanged:(NSPopUpButton*)sender
{
	_exportPanel.allowedFileTypes = @[sender.selectedTag == 0 ? (__bridge NSString*)kUTTypePropertyList : (__bridge NSString*)kUTTypeJSON];
}

- (IBAction)_export:(id)sender
{
	_exportPanel = [NSSavePanel new];
	_exportPanel.allowedFileTypes = @[_formatPopupButton.selectedTag == 0 ? (__bridge NSString*)kUTTypePropertyList : (__bridge NSString*)kUTTypeJSON];
	_exportPanel.allowsOtherFileTypes = NO;
	_exportPanel.canCreateDirectories = YES;
	_exportPanel.treatsFilePackagesAsDirectories = NO;
	_exportPanel.nameFieldLabel = NSLocalizedString(@"Export Data As", @"");
	_exportPanel.nameFieldStringValue = [self.document displayName].lastPathComponent.stringByDeletingPathExtension;
	
	_exportPanel.accessoryView = _exportPanelOptions;
	
	[_exportPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
		[_exportPanel orderOut:nil];
		
		if(result != NSModalResponseOK)
		{
			_exportPanel = nil;
			return;
		}
		
		NSData* data = nil;
		NSError* error = nil;
		
		if(_formatPopupButton.selectedTag == 0)
		{
			data = [NSPropertyListSerialization dataWithPropertyList:[((DTXDocument*)self.document).recording dictionaryRepresentationForPropertyList] format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
		}
		else
		{
			data = [NSJSONSerialization dataWithJSONObject:[((DTXDocument*)self.document).recording dictionaryRepresentationForJSON] options:NSJSONWritingPrettyPrinted error:&error];
		}
		
		if(data != nil)
		{
			[data writeToURL:_exportPanel.URL atomically:YES];
		}
		else if(error != nil)
		{
			[self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:nil];
		}
		
		_exportPanel = nil;
	}];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [super windowTitleForDocumentDisplayName:displayName];
}

@end
