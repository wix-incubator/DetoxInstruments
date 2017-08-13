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

static NSString* const __DTXBottomPaneCollapsed = @"DTXBottomPaneCollapsed";
static NSString* const __DTXRightInspectorCollapsed = @"DTXRightInspectorCollapsed";

@interface DTXInstrumentsWindowController () <DTXMainContentControllerDelegate, DTXBottomContentControllerDelegate>
{
	__weak IBOutlet NSSegmentedControl* _layoutSegmentControl;
	
	__weak IBOutlet NSButton* _titleLabelContainer;
	NSTextField* _titleTextField;
	
	__weak IBOutlet NSButton* _stopRecordingButton;
	__weak IBOutlet NSButton* _flagButton;
	
	DTXMainBottomPaneSplitViewController* _bottomSplitViewController;
	DTXBottomInspectorSplitViewController* _rightSplitViewController;
	
	DTXMainContentController* _mainContentController;
	DTXBottomContentController* _bottomContentController;
	DTXRightInspectorController* _inspectorContentController;
	
	BOOL _bottomCollapsed;
	BOOL _rightCollapsed;
}

@end

@implementation DTXInstrumentsWindowController

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
		
		if(((DTXDocument*)self.document).documentState >= DTXDocumentStateLiveRecordingFinished)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", ((DTXDocument*)self.document).recording.appName, [ivFormatter stringFromDate:((DTXDocument*)self.document).recording.startTimestamp toDate:((DTXDocument*)self.document).recording.endTimestamp]];
		}
		else if(((DTXDocument*)self.document).documentState == DTXDocumentStateLiveRecording)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", ((DTXDocument*)self.document).recording.appName, NSLocalizedString(@"Recording...", @"")];
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
	_stopRecordingButton.alphaValue = [(DTXDocument*)self.document documentState] == DTXDocumentStateLiveRecording;
	_flagButton.alphaValue = [(DTXDocument*)self.document documentState] == DTXDocumentStateLiveRecording;
}

- (IBAction)_stopRecordingButtonPressed:(id)sender
{
	[(DTXDocument*)self.document stopLiveRecording];
}

- (IBAction)_flagButtonPressed:(id)sender
{
	[(DTXDocument*)self.document addTag];
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

- (IBAction)segmentCellAction:(NSSegmentedCell*)sender
{
	NSInteger selectedSegment = [sender selectedSegment];
	
	switch(selectedSegment)
	{
		case 0:
			_bottomCollapsed = !_bottomCollapsed;
			break;
		case 1:
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
			break;
	}
	
	[self _fixUpSegments];
	[self _fixUpSplitViewsAnimated:YES];
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
	return self.targetForCopy && self.handlerForCopy != nil && self.handlerForCopy.canCopy;
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

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [super windowTitleForDocumentDisplayName:displayName];
}

@end
