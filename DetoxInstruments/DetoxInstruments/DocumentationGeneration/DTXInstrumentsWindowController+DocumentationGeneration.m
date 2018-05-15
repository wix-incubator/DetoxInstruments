//
//  DTXInstrumentsWindowController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#ifdef DEBUG

#import "DTXInstrumentsWindowController+DocumentationGeneration.h"
#import "DTXMainContentController.h"
#import "DTXManagedPlotControllerGroup.h"
#import "NSView+Snapshotting.h"
#import "NSWindow+Snapshotting.h"
#import "DTXSamplePlotController.h"
#import "DTXRecordingTargetPickerViewController+DocumentationGeneration.h"
#import "DTXRightInspectorController.h"

@interface NSObject ()

- (IBAction)options:(id)sender;

@end

@interface DTXInstrumentsWindowController ()

- (void)_fixUpTitle;

@end

@implementation DTXInstrumentsWindowController (DocumentationGeneration)

- (void)_drainLayout
{
	[self.window layoutIfNeeded];
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
}

- (void)_setWindowSize:(NSSize)size
{
	[self.window setFrame:(CGRect){0, 0, size} display:YES];
	[self.window center];
}

- (void)_deselectAnyPlotControllers
{
	NSOutlineView* hostingOutline = [self valueForKeyPath:@"mainContentController.tableView"];
	hostingOutline.allowsEmptySelection = YES;
	[hostingOutline deselectAll:nil];
}

- (id<DTXPlotController>)_plotControllerForClass:(Class)cls
{
	DTXManagedPlotControllerGroup* group = [self valueForKeyPath:@"mainContentController.plotGroup"];
	
	__block id<DTXPlotController> plotController;
	[group.plotControllers enumerateObjectsUsingBlock:^(id<DTXPlotController>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isMemberOfClass:cls])
		{
			*stop = YES;
			plotController = obj;
		}
	}];
	
	return plotController;
}

- (void)_selectPlotControllerOfClass:(Class)cls
{
	id plotController = [self _plotControllerForClass:cls];
	NSOutlineView* hostingOutline = [self valueForKeyPath:@"mainContentController.tableView"];
	[hostingOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:[hostingOutline rowForItem:plotController]] byExtendingSelection:NO];
}

- (NSImage*)_snapshotForPlotControllerOfClass:(Class)cls
{
	[self _drainLayout];
	id plotController = [self _plotControllerForClass:cls];
	NSOutlineView* hostingOutline = [self valueForKeyPath:@"mainContentController.tableView"];
	
	return [[hostingOutline rowViewAtRow:[hostingOutline rowForItem:plotController] makeIfNecessary:NO] snapshotForCachingDisplay];
}

- (NSImage*)_snapshotForTimeline;
{
	[self _drainLayout];
	NSOutlineView* hostingOutline = [self valueForKeyPath:@"mainContentController.tableView"];
	
	return hostingOutline.snapshotForCachingDisplay;
}

- (void)_setBottomSplitAtPercentage:(CGFloat)percentage
{
	NSSplitView* splitView = [self valueForKeyPath:@"bottomSplitViewController.splitView"];
	[splitView setPosition:self.window.frame.size.height * (1.0 - percentage) ofDividerAtIndex:0];
}

- (void)_deselectAnyDetail
{
	NSOutlineView* outline = [self valueForKeyPath:@"bottomContentController.activeDetailController.outlineView"];
	[outline deselectAll:nil];
}

- (NSImage*)_snapshotForDetailPane
{
	[self _drainLayout];
	return [[self valueForKey:@"bottomContentController"] view].snapshotForCachingDisplay;
}

- (void)_scrollBottomPaneToPercentage:(CGFloat)percentage
{
	NSOutlineView* outline = [self valueForKeyPath:@"bottomContentController.activeDetailController.outlineView"];
	NSScrollView* scrollView = outline.enclosingScrollView;
	[self _removeDetailVerticalScroller];
	
	[scrollView.contentView scrollPoint:NSMakePoint(0, outline.bounds.size.height * percentage)];
}

- (void)_removeDetailVerticalScroller
{
	NSOutlineView* outline = [self valueForKeyPath:@"bottomContentController.activeDetailController.outlineView"];
	outline.enclosingScrollView.hasVerticalScroller = NO;
}

- (void)_selectSampleAtIndex:(NSInteger)index forPlotControllerClass:(Class)cls
{
	[self _drainLayout];
	__kindof id<DTXPlotController> plotController = [self _plotControllerForClass:cls];
	NSArray* samples = [plotController samplesForPlotIndex:0];
	
	if(index == -1)
	{
		index = samples.count / 2;
	}
	
	[(NSOutlineView*)[self valueForKeyPath:@"bottomContentController.activeDetailController.outlineView"] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	
	[plotController highlightSample:samples[index]];
}

- (NSImage*)_snapshotForInspectorPane
{
	[self _drainLayout];
	return [[self valueForKey:@"inspectorContentController"] view].snapshotForCachingDisplay;
}

- (NSImage*)_snapshotForRecordingSettings
{
	[self _drainLayout];
	[self _drainLayout];
	DTXRecordingTargetPickerViewController* targetPicker = (id)self.window.sheets.firstObject.contentViewController;
	[targetPicker options:nil];
	[self _drainLayout];
	[self _drainLayout];
	
	NSWindow* window = self.window.sheets.firstObject;
	return [window snapshotForCachingDisplay];
}

- (NSImage*)_snapshotForTargetSelection
{
	[self _drainLayout];
	[self _drainLayout];
	DTXRecordingTargetPickerViewController* targetPicker = (id)self.window.sheets.firstObject.contentViewController;
	[targetPicker _addFakeTarget];
	[self _drainLayout];
	[self _drainLayout];
	
	NSWindow* window = self.window.sheets.firstObject;
	return [window snapshotForCachingDisplay];
}

- (void)_triggerDetailMenu;
{
	NSView* topView = [self valueForKeyPath:@"bottomContentController.topView"];
	NSRect frame = [self.window.contentView convertRect:topView.bounds fromView:topView];
	NSPoint pointOfTopView = NSMakePoint(frame.origin.x + 30, NSMidY(frame));
	
	NSEvent* event = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown location:pointOfTopView modifierFlags:0 timestamp:0 windowNumber:self.window.windowNumber context:nil eventNumber:0 clickCount:1 pressure:1.0];

	[NSApp sendEvent:event];
}

- (void)_setRecordingButtonsVisible:(BOOL)recordingButtonsVisible
{
	[[self valueForKey:@"stopRecordingButton"] setEnabled:recordingButtonsVisible];
	[[self valueForKey:@"stopRecordingButton"] setHidden:!recordingButtonsVisible];
	
	[[self valueForKey:@"flagButton"] setEnabled:recordingButtonsVisible];
	[[self valueForKey:@"flagButton"] setHidden:!recordingButtonsVisible];
	
	if(recordingButtonsVisible)
	{
		[[self valueForKey:@"_titleTextField"] setStringValue:[NSString stringWithFormat:@"%@ | %@", @"Example App", @"Recording..."]];
	}
	else
	{
		[self _fixUpTitle];
	}
}

- (void)_selectExtendedDetailInspector
{
	[[self valueForKeyPath:@"inspectorContentController"] selectExtendedDetail];
}

- (void)_selectProfilingInfoInspector
{
	[[self valueForKeyPath:@"inspectorContentController"] selectProfilingInfo];
}

- (DTXProfilingTargetManagementWindowController*)_openManagementWindowController
{
	[self _drainLayout];
	DTXRecordingTargetPickerViewController* targetPicker = (id)self.window.sheets.firstObject.contentViewController;
	return [targetPicker _openManagementWindowController];
}

@end

#endif
