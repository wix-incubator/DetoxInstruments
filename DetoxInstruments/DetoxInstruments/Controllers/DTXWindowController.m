//
//  DTXWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
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
#import "DTXLoadingWindowController.h"
#import "DTXSignpostSample+UIExtensions.h"

@import QuartzCore;

extern OSStatus DTXGoToHelpPage(NSString* pagePath);

static NSString* const __DTXWindowTitleVisibility = @"__DTXWindowTitleVisibility";
static NSString* const __DTXWindowToolbarStyle API_AVAILABLE(macos(11.0)) = @"__DTXWindowToolbarStyle";

@interface DTXProfilerWindow : NSWindow @end

@implementation DTXProfilerWindow

@end

@interface DTXWindowController () <DTXPlotAreaContentControllerDelegate, DTXDetailContentControllerDelegate, NSWindowDelegate>
{
	__weak IBOutlet NSSegmentedControl* _layoutSegmentControl;
	
	__weak IBOutlet NSButton* _titleLabelContainer;
	NSTextField* _titleTextField;
	
	__weak IBOutlet NSButton* _stopRecordingButton;
	__weak IBOutlet NSButton* _flagButton;
	__weak IBOutlet NSButton* _nowButton;
	__weak IBOutlet NSButton* _customizeButton;
	
	DTXPlotDetailSplitViewController* _plotDetailsSplitViewController;
	DTXDetailInspectorSplitViewController* _detailInspectorSplitViewController;
	
	DTXPlotAreaContentController* _plotContentController;
	DTXDetailContentController* _detailContentController;
	DTXInspectorContentController* _inspectorContentController;
	
	DTXLoadingWindowController* _loadingModalWindow;
	NSModalSession _loadingModalSession;
}

@end

@implementation DTXWindowController

+ (void)load
{
	@autoreleasepool
	{
		if (@available(macOS 11.0, *))
		{
			[NSUserDefaults.standardUserDefaults registerDefaults:@{__DTXWindowToolbarStyle: @(NSWindowToolbarStyleExpanded)}];
		}
	}
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.window.delegate = self;
	
	self.window.toolbar.centeredItemIdentifier = @"TitleToolbarItem";
	
	if(@available(macOS 11.0, *))
	{
		self.window.titleVisibility = NSWindowTitleVisible;
		self.window.toolbarStyle = [NSUserDefaults.standardUserDefaults integerForKey:__DTXWindowToolbarStyle];
		
		NSImage* stopImage = [NSImage imageWithSystemSymbolName:@"stop.fill" accessibilityDescription:nil];
		stopImage.size = CGSizeMake(15, 15);
		
		_stopRecordingButton.image = stopImage;
		
		NSImage* customizeImage = [NSImage imageWithSystemSymbolName:@"list.dash" accessibilityDescription:nil];
		customizeImage.size = CGSizeMake(15, 15);
		
		_customizeButton.image = customizeImage;
	}
	else
	{
		self.window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
		self.window.titleVisibility = [NSUserDefaults.standardUserDefaults integerForKey:__DTXWindowTitleVisibility];
	}
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
		[NSNotificationCenter.defaultCenter removeObserver:self name:DTXRecordingDocumentStateDidChangeNotification object:self.document];
	}
	
	[super setDocument:document];
	
	if(self.document != nil)
	{
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXRecordingDocumentStateDidChangeNotification object:self.document];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_appLaunchProfilingStateDidChangeNotification:) name:DTXRecordingLocalRecordingProfilingStateDidChangeNotification object:self.document];
	}
	
	if(document == nil)
	{
		return;
	}
	
	if(document.documentState == DTXRecordingDocumentStateSavedToDisk && [DTXSignpostSample countOfSamplesInManagedObjectContext:document.viewContext] > 7000)
	{
		_loadingModalWindow = [[NSStoryboard storyboardWithName:@"Profiler" bundle:[NSBundle bundleForClass:self.class]] instantiateControllerWithIdentifier:@"migrationIndicator"];
		[_loadingModalWindow setLoadingTitle:[NSString stringWithFormat:@"Loading %@…", document.fileURL.lastPathComponent]];
		_loadingModalSession = [NSApp beginModalSessionForWindow:_loadingModalWindow.window];
		[NSApp runModalSession:_loadingModalSession];
	}
	
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
		
		_titleTextField.font = [NSFont monospacedDigitSystemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightRegular];
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

- (void)windowDidChangeOcclusionState:(NSNotification *)notification
{
	if((self.window.occlusionState & NSWindowOcclusionStateVisible) != 0)
	{
		if(_loadingModalWindow != nil)
		{
			[NSApp endModalSession:_loadingModalSession];
			[_loadingModalWindow.window close];
			_loadingModalWindow = nil;
			
			[self.window becomeKeyWindow];
		}
	}
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	[self _fixUpRecordingButtons];
	[self _fixUpTitle];
	
	self.window.restorable = [(DTXRecordingDocument*)self.document documentState] >= DTXRecordingDocumentStateLiveRecordingFinished;
}

- (void)_appLaunchProfilingStateDidChangeNotification:(NSNotification*)note
{
	DTXRecordingDocument* document = self.document;
	
	switch (document.localRecordingProfilingState) {
		case DTXRecordingLocalRecordingProfilingStateUnknown:
			[_plotDetailsSplitViewController setSplitViewHidden:NO];
			[_plotDetailsSplitViewController setProgressIndicatorTitle:nil subtitle:nil displaysProgress:NO];
			break;
		case DTXRecordingLocalRecordingProfilingStateWaitingForAppLaunch:
			[_plotDetailsSplitViewController setSplitViewHidden:YES];
			[_plotDetailsSplitViewController setProgressIndicatorTitle:NSLocalizedString(@"Waiting for App", @"") subtitle:NSLocalizedString(@"Launch Your App to Start Profiling", @"") displaysProgress:NO];
			break;
		case DTXRecordingLocalRecordingProfilingStateWaitingForAppData:
			[_plotDetailsSplitViewController setSplitViewHidden:YES];
			[_plotDetailsSplitViewController setProgressIndicatorTitle:NSLocalizedString(@"Recording...", @"") subtitle:nil displaysProgress:YES];
			break;
	}
	
	[self _fixUpTitle];
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
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", document.localRecordingProfilingState == DTXRecordingLocalRecordingProfilingStateWaitingForAppData ? document.localRecordingPendingAppName : document.firstRecording.appName, NSLocalizedString(@"Recording…", @"")];
		}
		else if(document.localRecordingProfilingState > DTXRecordingLocalRecordingProfilingStateUnknown)
		{
			_titleTextField.stringValue = [NSString stringWithFormat:@"%@ | %@", document.localRecordingPendingAppName, NSLocalizedString(@"App Launch Profiling", @"")];
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
	DTXRecordingDocument* document = self.document;
	_stopRecordingButton.enabled = document.documentState == DTXRecordingDocumentStateLiveRecording;
	_stopRecordingButton.hidden = !_stopRecordingButton.enabled;
	_flagButton.enabled = _nowButton.enabled = document.documentState == DTXRecordingDocumentStateLiveRecording && document.localRecordingProfilingState == DTXRecordingLocalRecordingProfilingStateUnknown;
	_nowButton.hidden = !_nowButton.enabled;
	_flagButton.hidden = !_flagButton.enabled;
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
	_inspectorContentController.inspectorDataProvider = nil;
	
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
	_inspectorContentController.inspectorDataProvider = inspectorProvider;
	
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
	
	if([menuItem.identifier isEqualToString:@"DTXToolbarStyleMenu"])
	{
		if_unavailable(macOS 11.0, *)
		{
			menuItem.hidden = YES;
			
			return NO;
		}
	}
	
	if(menuItem.action == @selector(_unifiedToolbar:) || menuItem.action == @selector(_expandedToolbar:))
	{
		if(@available(macOS 11.0, *))
		{
			menuItem.state = menuItem.tag == [NSUserDefaults.standardUserDefaults integerForKey:__DTXWindowToolbarStyle] ? NSControlStateValueOn : NSControlStateValueOff;
			
			return YES;
		}
		
		menuItem.hidden = YES;
		
		return NO;
	}
	
	if(menuItem.action == @selector(_toggleTitleVisibility:))
	{
		if(@available(macOS 11.0, *))
		{
			menuItem.hidden = YES;
			
			return NO;
		}
		
		menuItem.title = self.window.titleVisibility == NSWindowTitleHidden ? NSLocalizedString(@"Show Window Title", @"") : NSLocalizedString(@"Hide Window Title", @"");
		
		return YES;
	}
	
	if(menuItem.action == @selector(fitAllData:) || menuItem.action == @selector(zoomIn:) || menuItem.action == @selector(zoomOut:))
	{
		return YES;
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

- (IBAction)_unifiedToolbar:(id)sender API_AVAILABLE(macos(11.0))
{
	self.window.toolbarStyle = NSWindowToolbarStyleUnified;
	
	[NSUserDefaults.standardUserDefaults setInteger:NSWindowToolbarStyleUnified forKey:__DTXWindowToolbarStyle];
}

- (IBAction)_expandedToolbar:(id)sender API_AVAILABLE(macos(11.0))
{
	self.window.toolbarStyle = NSWindowToolbarStyleExpanded;
	
	[NSUserDefaults.standardUserDefaults setInteger:NSWindowToolbarStyleExpanded forKey:__DTXWindowToolbarStyle];
}

- (IBAction)_toggleTitleVisibility:(id)sender
{
	if(@available(macOS 11.0, *))
	{
		return;
	}
	
	self.window.titleVisibility = 1 - self.window.titleVisibility;
	
	[self.window.tabbedWindows enumerateObjectsUsingBlock:^(NSWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.titleVisibility = self.window.titleVisibility;
	}];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _resetWindowTitles];
	});
	
	[NSUserDefaults.standardUserDefaults setInteger:self.window.titleVisibility forKey:__DTXWindowTitleVisibility];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
	if([self.document documentState] == DTXRecordingDocumentStateNew)
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
