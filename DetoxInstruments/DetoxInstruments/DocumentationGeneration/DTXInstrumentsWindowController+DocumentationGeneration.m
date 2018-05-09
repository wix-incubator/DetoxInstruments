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
#import "DTXSamplePlotController.h"

@implementation DTXInstrumentsWindowController (DocumentationGeneration)

- (void)_drainLayout
{
	[self.window.contentView layoutSubtreeIfNeeded];
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

- (void)_setWindowSizeToScreenPercentage:(CGPoint)percentage
{
	[self.window setFrame:(CGRect){0, 0, CGSizeApplyAffineTransform(self.window.screen.frame.size, CGAffineTransformMakeScale(percentage.x , percentage.y))} display:YES];
	[self.window center];
}

- (void)_deselectAllPlotControllers
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
	
	[scrollView.contentView scrollPoint:NSMakePoint(0, outline.bounds.size.height * percentage)];
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

@end

#endif
