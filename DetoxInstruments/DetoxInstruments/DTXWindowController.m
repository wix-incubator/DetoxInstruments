//
//  DTXWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXWindowController.h"
#import "DTXPlotDetailSplitViewController.h"
#import "DTXDetailInspectorSplitViewController.h"
#import "DTXPlotAreaContentController.h"
#import "DTXDetailContentController.h"
#import "DTXInspectorContentController.h"
#import "DTXRecordingDocument.h"
#import <CoreServices/CoreServices.h>
#import "DTXRecording+UIExtensions.h"

@import QuartzCore;

static NSString* const __DTXWindowTitleVisibility = @"__DTXWindowTitleVisibility";

@interface DTXWindowController () <DTXPlotAreaContentControllerDelegate, DTXDetailContentControllerDelegate>
{
	__weak IBOutlet NSSegmentedControl* _layoutSegmentControl;
	
	__weak IBOutlet NSButton* _titleLabelContainer;
	NSTextField* _titleTextField;
	
	__weak IBOutlet NSButton* _stopRecordingButton;
	__weak IBOutlet NSButton* _flagButton;
	__weak IBOutlet NSButton* _pushGroupButton;
	__weak IBOutlet NSButton* _popGroupButton;
	
	DTXPlotDetailSplitViewController* _plotDetailsSplitViewController;
	DTXDetailInspectorSplitViewController* _detailInspectorSplitViewController;
	
	DTXPlotAreaContentController* _plotContentController;
	DTXDetailContentController* _detailContentController;
	DTXInspectorContentController* _inspectorContentController;
}

@end

@implementation DTXWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.window.titleVisibility = [NSUserDefaults.standardUserDefaults integerForKey:__DTXWindowTitleVisibility];
}

- (void)setContentViewController:(NSViewController *)contentViewController
{
	[super setContentViewController:contentViewController];
	
	_plotDetailsSplitViewController = (id)self.window.contentViewController;
	_detailInspectorSplitViewController = (id)self.window.contentViewController.childViewControllers.lastObject;
	
	_plotContentController = (id)_plotDetailsSplitViewController.splitViewItems.firstObject.viewController;
	_detailContentController = (id)_detailInspectorSplitViewController.splitViewItems.firstObject.viewController;
	_inspectorContentController = (id)_detailInspectorSplitViewController.splitViewItems.lastObject.viewController;
	
	_plotContentController.delegate = self;
	_detailContentController.delegate = self;
	
	self.window.contentView.wantsLayer = YES;
	self.window.contentView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	[self.window setFrame:(CGRect){0, 0, CGSizeApplyAffineTransform(self.window.screen.frame.size, CGAffineTransformMakeScale(0.85 , 0.85))} display:YES];
	[self.window center];
	
//	(origin = (x = 516, y = 85), size = (width = 1065, height = 893))
//	[self.window setFrame:NSMakeRect(516, 85, 1065, 893) display:YES];
}

- (void)setDocument:(DTXRecordingDocument*)document
{
	if(self.document != nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:DTXRecordingDocumentStateDidChangeNotification object:self.document];
	}
	
	[super setDocument:document];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXRecordingDocumentStateDidChangeNotification object:self.document];
	
	[self _fixUpRecordingButtons];
	
	_plotDetailsSplitViewController.document = self.document;
	_plotContentController.document = self.document;
	_detailContentController.document = self.document;
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
		_titleTextField.textColor = [NSColor controlTextColor];
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
	
	self.window.restorable = [(DTXRecordingDocument*)self.document documentState] >= DTXRecordingDocumentStateLiveRecordingFinished;
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	[self _fixUpRecordingButtons];
	[self _fixUpTitle];
	
	self.window.restorable = [(DTXRecordingDocument*)self.document documentState] >= DTXRecordingDocumentStateLiveRecordingFinished;
}

- (void)_fixUpTitle
{
	if(self.document != nil)
	{
		NSDateComponentsFormatter* ivFormatter = [NSDateComponentsFormatter new];
		ivFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
		
		DTXRecordingDocument* document = (DTXRecordingDocument*)self.document;
		
		if(document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished && document.recording.startTimestamp && document.recording.endTimestamp)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", document.recording.appName, [ivFormatter stringFromDate:document.recording.startTimestamp toDate:document.recording.endTimestamp]];
		}
		else if(document.documentState == DTXRecordingDocumentStateLiveRecording)
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
	_stopRecordingButton.enabled = [(DTXRecordingDocument*)self.document documentState] == DTXRecordingDocumentStateLiveRecording;
	_stopRecordingButton.hidden = !_stopRecordingButton.enabled;
	
	_flagButton.enabled = [(DTXRecordingDocument*)self.document documentState] == DTXRecordingDocumentStateLiveRecording;
	_flagButton.hidden = !_flagButton.enabled;
	
	_pushGroupButton.enabled = 0.0; //[(DTXRecordingDocument*)self.document documentState] == DTXRecordingDocumentStateLiveRecording;
	_pushGroupButton.hidden = !_pushGroupButton.enabled;
	
	_popGroupButton.enabled = _popGroupButton.hidden = 0.0; //[(DTXRecordingDocument*)self.document documentState] == DTXRecordingDocumentStateLiveRecording;
	_popGroupButton.hidden = !_popGroupButton.enabled;
}

- (IBAction)_stopRecordingButtonPressed:(id)sender
{
	[(DTXRecordingDocument*)self.document stopLiveRecording];
}

- (IBAction)_flagButtonPressed:(id)sender
{
	[(DTXRecordingDocument*)self.document addTag];
}

- (IBAction)_pushGroupButtonPressed:(id)sender
{
	[(DTXRecordingDocument*)self.document pushGroup];
}

- (IBAction)_popGroupButtonPressed:(id)sender
{
	[(DTXRecordingDocument*)self.document popGroup];
}

- (IBAction)zoomIn:(id)sender
{
	[_plotContentController zoomIn];
}

- (IBAction)zoomOut:(id)sender
{
	[_plotContentController zoomOut];
}

- (IBAction)fitAllData:(id)sender
{
	[_plotContentController fitAllData];
}

- (void)contentController:(DTXPlotAreaContentController*)cc updatePlotController:(id<DTXPlotController>)plotController
{
	_detailContentController.managingPlotController = plotController;
	_inspectorContentController.moreInfoDataProvider = nil;
}

- (void)bottomController:(DTXDetailContentController*)bc updateWithInspectorProvider:(DTXInspectorDataProvider*)inspectorProvider
{
	_inspectorContentController.moreInfoDataProvider = inspectorProvider;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(_toggleTitleVisibility:))
	{
		menuItem.title = self.window.titleVisibility == NSWindowTitleHidden ? NSLocalizedString(@"Show Window Title", @"") : NSLocalizedString(@"Hide Window Title", @"");
		
		return YES;
	}
	
	if(menuItem.action == @selector(fitAllData:) || menuItem.action == @selector(zoomIn:) || menuItem.action == @selector(zoomOut:))
	{
		return YES;
	}
	
	if(menuItem.action == @selector(copy:))
	{
		return self.targetForCopy && self.handlerForCopy != nil && self.handlerForCopy.canCopy;
	}
	
	return NO;
}

- (void)_resetWindowTitles
{
	NSURL* url = self.window.representedURL;
	[self.window setRepresentedURL:nil];
	[self.window setRepresentedURL:url];
	
	[self.window.tabbedWindows enumerateObjectsUsingBlock:^(NSWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSURL* url = obj.representedURL;
		[obj setRepresentedURL:nil];
		[obj setRepresentedURL:url];
	}];
}

- (IBAction)_toggleTitleVisibility:(id)sender
{
	self.window.titleVisibility = 1 - self.window.titleVisibility;
	
	[self.window.tabbedWindows enumerateObjectsUsingBlock:^(NSWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.titleVisibility = self.window.titleVisibility;
	}];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _resetWindowTitles];
	});
	
	[NSUserDefaults.standardUserDefaults setInteger:self.window.titleVisibility forKey:__DTXWindowTitleVisibility];
}

- (IBAction)copy:(id)sender
{
	[self.handlerForCopy copy:sender targetView:self.targetForCopy];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
	if([self.document documentState] == DTXRecordingDocumentStateNew)
	{
		return;
	}
	
	[super encodeRestorableStateWithCoder:coder];
}

- (void)setHandlerForCopy:(id<DTXWindowWideCopyHanler>)handlerForCopy
{
	_handlerForCopy = handlerForCopy;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [super windowTitleForDocumentDisplayName:displayName];
}

@end
