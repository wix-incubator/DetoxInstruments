//
//  DTXWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
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

extern OSStatus DTXGoToHelpPage(NSString* pagePath);

static NSString* const __DTXWindowTitleVisibility = @"__DTXWindowTitleVisibility";

@interface DTXWindowController () <DTXPlotAreaContentControllerDelegate, DTXDetailContentControllerDelegate>
{
	__weak IBOutlet NSSegmentedControl* _layoutSegmentControl;
	
	__weak IBOutlet NSButton* _titleLabelContainer;
	NSTextField* _titleTextField;
	
	__weak IBOutlet NSButton* _stopRecordingButton;
	__weak IBOutlet NSButton* _flagButton;
	__weak IBOutlet NSButton* _nowButton;
	
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
	
	[self.window setFrame:(CGRect){0, 0, CGSizeApplyAffineTransform(self.window.screen.frame.size, CGAffineTransformMakeScale(0.85 , 0.85))} display:YES];
	[self.window center];
	
	_plotDetailsSplitViewController = (id)self.window.contentViewController;
	_detailInspectorSplitViewController = (id)self.window.contentViewController.childViewControllers.lastObject;
	
	_plotContentController = (id)_plotDetailsSplitViewController.splitViewItems.firstObject.viewController;
	_detailContentController = (id)_detailInspectorSplitViewController.splitViewItems.firstObject.viewController;
	_inspectorContentController = (id)_detailInspectorSplitViewController.splitViewItems.lastObject.viewController;
	
	_plotContentController.delegate = self;
	_detailContentController.delegate = self;
	
	self.window.contentView.wantsLayer = YES;
	self.window.contentView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
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
	_inspectorContentController.document = self.document;
	_detailContentController.document = self.document;
	_plotContentController.document = self.document;
	
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
		
		if(document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished && document.firstRecording.startTimestamp && document.lastRecording.endTimestamp)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", document.firstRecording.appName, [ivFormatter stringFromDate:document.firstRecording.startTimestamp toDate:document.lastRecording.endTimestamp]];
		}
		else if(document.documentState == DTXRecordingDocumentStateLiveRecording)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", document.firstRecording.appName, NSLocalizedString(@"Recording…", @"")];
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
	
	_nowButton.enabled = [(DTXRecordingDocument*)self.document documentState] == DTXRecordingDocumentStateLiveRecording;
	_nowButton.hidden = !_nowButton.enabled;
}

- (IBAction)_stopRecording:(id)sender
{
	[(DTXRecordingDocument*)self.document stopLiveRecording];
}

- (IBAction)_addFlag:(id)sender
{
	[(DTXRecordingDocument*)self.document addTag];
}

- (IBAction)zoomIn:(id)sender
{
	[_plotContentController zoomIn];
}

- (IBAction)zoomOut:(id)sender
{
	[_plotContentController zoomOut];
}

- (IBAction)editInstruments:(id)sender
{
	[_plotContentController presentPlotControllerPickerFromView:sender];
}

- (IBAction)fitAllData:(id)sender
{
	[_plotContentController fitAllData];
}

- (void)contentController:(DTXPlotAreaContentController*)cc updatePlotController:(id<DTXPlotController>)plotController
{
	_detailContentController.managingPlotController = plotController;
	_inspectorContentController.moreInfoDataProvider = nil;
	
	[self reloadTouchBar];
}

- (IBAction)_toggleNowMode:(NSControl*)sender
{
	[self _setNowModeEnabled:!_plotContentController.nowModeEnabled];
}

- (void)_setNowModeEnabled:(BOOL)enabled
{
	[_plotContentController setNowModeEnabled:enabled];
	_nowButton.state = enabled ? NSControlStateValueOn : NSControlStateValueOff;
	[self _resetNowModeButtonImage];
}

- (void)_resetNowModeButtonImage
{
	NSString* imageName = [NSString stringWithFormat:@"NowTemplate%@", _nowButton.state == NSControlStateValueOn ? @"On" : @""];
	_nowButton.image = [NSImage imageNamed:imageName];
}

- (void)contentControllerDidDisableNowFollowing:(DTXPlotAreaContentController*)cc
{
	[self _setNowModeEnabled:NO];
}

- (id)currentPlotController
{
	return _detailContentController.managingPlotController;
}

- (void)reloadTouchBar
{
	NSTouchBar *bar = [[NSTouchBar alloc] init];
	bar.delegate = (id)_plotContentController;
	
	// Set the default ordering of items.
	bar.defaultItemIdentifiers = @[@"TouchBarPlotControllerSelector", @"TouchBarPlotController"];
	
	self.touchBar = bar;
}

- (void)bottomController:(DTXDetailContentController*)bc updateWithInspectorProvider:(DTXInspectorDataProvider*)inspectorProvider
{
	_inspectorContentController.moreInfoDataProvider = inspectorProvider;
	
	if(inspectorProvider != nil)
	{
		[self _setNowModeEnabled:NO];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(_showInstrumentHelp:))
	{
		BOOL enabled = _detailContentController.managingPlotController != nil;
		
		if(enabled)
		{
			menuItem.title = [NSString stringWithFormat:@"%@ %@", _detailContentController.managingPlotController.displayName, NSLocalizedString(@"Instrument Help", @"")];
		}
		
		if(menuItem.tag != 1)
		{
			menuItem.hidden = enabled == NO;
		}
		
		return enabled;
	}
	
	if(menuItem.action == @selector(_toggleNowMode:))
	{
		menuItem.hidden = [self.document documentState] != DTXRecordingDocumentStateLiveRecording;
		if(menuItem.hidden)
		{
			return NO;
		}
		
		menuItem.state = _plotContentController.nowModeEnabled ? NSControlStateValueOn : NSControlStateValueOff;
		
		return YES;
	}
	
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

- (IBAction)_showInstrumentHelp:(id)sender
{
	NSString* instrumentHelpTopic = [NSString stringWithFormat:@"Instrument_%@", _detailContentController.managingPlotController.helpTopicName];
	
	DTXGoToHelpPage(instrumentHelpTopic);
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
