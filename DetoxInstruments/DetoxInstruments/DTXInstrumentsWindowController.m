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

static NSString* const __DTXBottomPaneCollapsed = @"DTXBottomPaneCollapsed";
static NSString* const __DTXRightInspectorCollapsed = @"DTXRightInspectorCollapsed";

@interface DTXInstrumentsWindowController () <DTXMainContentControllerDelegate>
{
	__weak IBOutlet NSSegmentedControl *_layoutSegmentControl;
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

- (void)windowDidLoad {
    [super windowDidLoad];
	
	[self.window center];
    
	self.window.titleVisibility = NSWindowTitleHidden;
	
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
	
	[[NSUserDefaults standardUserDefaults] setBool:_bottomCollapsed forKey:__DTXBottomPaneCollapsed];
	[[NSUserDefaults standardUserDefaults] setBool:_rightCollapsed forKey:__DTXRightInspectorCollapsed];
}

- (void)contentController:(DTXMainContentController*)cc updateUIWithUIProvider:(DTXUIDataProvider*)dataProvider;
{
	_bottomContentController.managingDataProvider = dataProvider;
}

@end
