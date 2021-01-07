//
//  DTXPlotDetailSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXPlotDetailSplitViewController.h"
#import "DTXDetailInspectorSplitViewController.h"
#import "DTXPlotAreaContentController.h"
#import "DTXDetailContentController.h"
#import "DTXInspectorContentController.h"
#import "DTXWindowController.h"
#import "DTXRecordingDocumentDataExporter.h"
#import "DTXDetailController.h"
#import "NSString+FileNames.h"
@import QuartzCore;
@import Carbon.HIToolbox.Events;

static NSString* const __DTXBottomPaneCollapsed = @"DTXBottomPaneCollapsed";
static NSString* const __DTXRightInspectorCollapsed = @"DTXRightInspectorCollapsed";

@interface DTXPlotDetailSplitViewController ()
{
	BOOL _bottomCollapsed;
	BOOL _rightCollapsed;
	
	DTXDetailInspectorSplitViewController* _detailInspectorSplitViewController;
	
	DTXPlotAreaContentController* _plotContentController;
	DTXDetailContentController* _detailContentController;
	DTXInspectorContentController* _inspectorContentController;
	
	NSSavePanel* _exportPanel;
	IBOutlet NSView* _exportPanelOptions;
	IBOutlet NSPopUpButton* _formatPopupButton;
	
	BOOL _startedDisabledAndNotToggledYet;
	
	IBOutlet NSProgressIndicator* _progressIndicator;
	IBOutlet NSTextField* _progressIndicatorTextField;
	IBOutlet NSTextField* _progressIndicatorSubtitleTextField;
	IBOutlet NSStackView* _progressIndicatorContainer;
}

@end

@implementation DTXPlotDetailSplitViewController

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[_exportPanelOptions.heightAnchor constraintEqualToConstant:65].active = YES;
}

- (void)dealloc
{
	[self.splitViewItems.lastObject removeObserver:self forKeyPath:@"collapsed"];
	[_detailInspectorSplitViewController.splitViewItems.lastObject removeObserver:self forKeyPath:@"collapsed"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(_export:))
	{
		return ((DTXRecordingDocument*)self.document).documentState >= DTXRecordingDocumentStateLiveRecordingFinished;
	}
	
	if(menuItem.action == @selector(_exportInstrumentCSV:))
	{
		NSString* detailTitle = _detailContentController.activeDetailController.displayName;
		NSString* instrumentTitle = nil;
		if([_detailContentController.activeDetailController isKindOfClass:NSClassFromString(@"DTXLogDetailController")] == NO)
		{
			instrumentTitle = _detailContentController.managingPlotController.displayName;
		}
		
		menuItem.title = [NSString stringWithFormat:@"%@%@ %@", instrumentTitle ? [NSString stringWithFormat:@"%@ ", instrumentTitle] : @"", detailTitle, NSLocalizedString(@"As CSV…", @"")];
		
		BOOL enabled = ((DTXRecordingDocument*)self.document).documentState >= DTXRecordingDocumentStateLiveRecordingFinished && _detailContentController.activeDetailController.dataExporter != nil;
		
		menuItem.hidden = enabled == NO;
		
		return enabled;
	}
	
	return menuItem.action == @selector(toggleBottom:) || menuItem.action == @selector(selectExtendedDetail:) || menuItem.action == @selector(selectProfilingInfo:);
}

- (IBAction)selectExtendedDetail:(id)sender
{
	[_inspectorContentController selectExtendedDetail];
	
	if(_bottomCollapsed == YES || _rightCollapsed == YES)
	{
		[self toggleRight:nil];
	}
}

- (IBAction)selectProfilingInfo:(id)sender
{
	[_inspectorContentController selectProfilingInfo];
	
	if(_bottomCollapsed == YES || _rightCollapsed == YES)
	{
		[self toggleRight:nil];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.splitViewItems.lastObject.automaticMaximumThickness = 320;
	
	_bottomCollapsed = [NSUserDefaults.standardUserDefaults boolForKey:__DTXBottomPaneCollapsed];
	_rightCollapsed = [NSUserDefaults.standardUserDefaults boolForKey:__DTXRightInspectorCollapsed];
	
	_detailInspectorSplitViewController = (id)self.childViewControllers.lastObject;
	
	_plotContentController = (id)self.splitViewItems.firstObject.viewController;
	_detailContentController = (id)_detailInspectorSplitViewController.splitViewItems.firstObject.viewController;
	_inspectorContentController = (id)_detailInspectorSplitViewController.splitViewItems.lastObject.viewController;
	
	[self.splitViewItems.lastObject addObserver:self forKeyPath:@"collapsed" options:NSKeyValueObservingOptionNew context:NULL];
	[_detailInspectorSplitViewController.splitViewItems.lastObject addObserver:self forKeyPath:@"collapsed" options:NSKeyValueObservingOptionNew context:NULL];
	
	[self _fixUpSegments];
	[self _fixUpSplitViewsAnimated:NO];
	
	if(_bottomCollapsed)
	{
		_startedDisabledAndNotToggledYet = YES;
	}
	
	_progressIndicator.usesThreadedAnimation = YES;
	
	_progressIndicatorContainer.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:_progressIndicatorContainer];
	
	[NSLayoutConstraint activateConstraints:@[
		[self.view.centerXAnchor constraintEqualToAnchor:_progressIndicatorContainer.centerXAnchor],
		[self.view.centerYAnchor constraintEqualToAnchor:_progressIndicatorContainer.centerYAnchor],
	]];
	
	[self setProgressIndicatorTitle:nil subtitle:nil displaysProgress:NO];
	
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[self _fixUpSegments];
}

- (CGFloat)lastSplitItemMaxThickness
{
	return NSSplitViewItemUnspecifiedDimension;
}

- (CGFloat)lastSplitItemMinThickness
{
	return self.view.window == nil ? 320 : 88;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if([keyPath isEqualToString:@"collapsed"])
	{
		_bottomCollapsed = self.splitViewItems.lastObject.isCollapsed;
		_rightCollapsed = _detailInspectorSplitViewController.splitViewItems.lastObject.isCollapsed;
		
		[self _fixUpSegments];
		[self _fixUpSplitViewsAnimated:NO];
		
		[NSUserDefaults.standardUserDefaults setBool:_bottomCollapsed forKey:__DTXBottomPaneCollapsed];
		[NSUserDefaults.standardUserDefaults setBool:_rightCollapsed forKey:__DTXRightInspectorCollapsed];
		
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)_fixUpSegments
{
	NSSegmentedControl* _layoutSegmentControl = ((DTXWindowController*)self.view.window.windowController).layoutSegmentControl;
	
	[_layoutSegmentControl setSelected:!_bottomCollapsed forSegment:0];
	[_layoutSegmentControl setSelected:_bottomCollapsed ? NO : !_rightCollapsed forSegment:1];
}

- (void)_fixUpSplitViewsAnimated:(BOOL)animated
{
	NSSplitViewItem* bottomSplitViewItem = self.splitViewItems.lastObject;
	NSSplitViewItem* rightSplitViewItem = _detailInspectorSplitViewController.splitViewItems.lastObject;
	
	if(animated)
	{
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
			context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			context.allowsImplicitAnimation = YES;
			context.duration = animated ? 1.0 : 0;
			
			bottomSplitViewItem.animator.collapsed = _bottomCollapsed;
			rightSplitViewItem.animator.collapsed = _rightCollapsed;
			
//			[self.view.animator layoutSubtreeIfNeeded];
//			[_detailInspectorSplitViewController.view.animator layoutSubtreeIfNeeded];
		} completionHandler:^{
			bottomSplitViewItem.maximumThickness = self.lastSplitItemMaxThickness;
		}];
	}
	else
	{
		bottomSplitViewItem.collapsed = _bottomCollapsed;
		rightSplitViewItem.collapsed = _rightCollapsed;
	}
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
	
	_startedDisabledAndNotToggledYet = NO;
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

- (IBAction)_exportFormatChanged:(NSPopUpButton*)sender
{
	_exportPanel.allowedFileTypes = @[sender.selectedTag == 0 ? NS(kUTTypePropertyList) : NS(kUTTypeJSON)];
}

- (IBAction)_export:(id)sender
{
	_exportPanel = [NSSavePanel new];
	_exportPanel.allowedFileTypes = @[_formatPopupButton.selectedTag == 0 ? NS(kUTTypePropertyList) : NS(kUTTypeJSON)];
	_exportPanel.allowsOtherFileTypes = NO;
	_exportPanel.canCreateDirectories = YES;
	_exportPanel.treatsFilePackagesAsDirectories = NO;
	_exportPanel.nameFieldLabel = NSLocalizedString(@"Export Data As", @"");
	_exportPanel.nameFieldStringValue = [self.document displayName].lastPathComponent.stringByDeletingPathExtension;
	
	_exportPanel.accessoryView = _exportPanelOptions;
	
	[_exportPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
		[_exportPanel orderOut:nil];
		
		if(result != NSModalResponseOK)
		{
			_exportPanel = nil;
			return;
		}
		
		@autoreleasepool
		{
			NSData* data = nil;
			NSError* error = nil;
			
			DTXRecordingDocumentDataExporter* exporter = [[DTXRecordingDocumentDataExporter alloc] initWithDocument:self.document];
			data = [exporter exportDataWithType:(DTXDataExportType)_formatPopupButton.selectedTag error:&error];
			
			if(data != nil)
			{
				[data writeToURL:_exportPanel.URL atomically:YES];
			}
			else if(error != nil)
			{
				[self presentError:error modalForWindow:self.view.window delegate:nil didPresentSelector:nil contextInfo:nil];
			}
		}
		
		_exportPanel = nil;
	}];
}

- (IBAction)_exportInstrumentCSV:(id)sender
{
	DTXDataExporter* exporter = _detailContentController.activeDetailController.dataExporter;
	NSError* error;
	NSData* csvData = [exporter exportDataWithType:DTXDataExportTypeCSV error:&error];
	if(csvData == nil)
	{
		[self presentError:error modalForWindow:self.view.window delegate:nil didPresentSelector:nil contextInfo:nil];
		return;
	}
	
	_exportPanel = [NSSavePanel new];
	_exportPanel.allowedFileTypes = @[NS(kUTTypeCommaSeparatedText)];
	_exportPanel.allowsOtherFileTypes = NO;
	_exportPanel.canCreateDirectories = YES;
	_exportPanel.treatsFilePackagesAsDirectories = NO;
	_exportPanel.nameFieldLabel = NSLocalizedString(@"Export Data", @"");
	_exportPanel.nameFieldStringValue = [NSString stringWithFormat:@"%@ (%@)", [self.document displayName].lastPathComponent.stringByDeletingPathExtension, _detailContentController.managingPlotController.displayName].stringBySanitizingForFileName;
	
	[_exportPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
		[_exportPanel orderOut:nil];
		
		if(result != NSModalResponseOK)
		{
			_exportPanel = nil;
			return;
		}
		
		@autoreleasepool
		{
			[csvData writeToURL:_exportPanel.URL atomically:YES];
		}
		
		_exportPanel = nil;
	}];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)keyDown:(NSEvent *)event
{
	if(event.keyCode == kVK_Space)
	{
		//To prevent the system beeping.
		return;
	}
	
	[super keyDown:event];
}

- (void)keyUp:(NSEvent *)event
{
	if(event.keyCode == kVK_Space)
	{
		if([_detailInspectorSplitViewController expandPreview] == NO)
		{
			NSBeep();
		}
		return;
	}
	
	[super keyUp:event];
}

- (BOOL)splitViewHidden
{
	return self.splitView.alphaValue == 0.0;
}

- (void)setSplitViewHidden:(BOOL)splitViewHidden
{
	self.splitView.alphaValue = splitViewHidden ? 0.0 : 1.0;
}

- (void)setProgressIndicatorTitle:(nullable NSString*)progressIndicatorTitle subtitle:(nullable NSString*)subtitle displaysProgress:(BOOL)displaysProgress
{
	_progressIndicatorContainer.hidden = progressIndicatorTitle == nil;
	_progressIndicatorTextField.stringValue = progressIndicatorTitle ?: @"";
	_progressIndicatorSubtitleTextField.hidden = subtitle == nil;
	_progressIndicatorSubtitleTextField.stringValue = subtitle ?: @"";
	_progressIndicator.indeterminate = displaysProgress;
	if(_progressIndicator.indeterminate)
	{
		[_progressIndicator startAnimation:nil];
	}
	else
	{
		[_progressIndicator stopAnimation:nil];
	}
	[_progressIndicatorContainer invalidateIntrinsicContentSize];
}

@end
