//
//  DTXDetailContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDetailContentController.h"
#import "DTXRecordingDocument.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXLogDetailController.h"
#import "DTXMenuPathControl.h"
#import "DTXFilterField.h"

@interface DTXDetailContentController () <DTXMenuPathControlDelegate, DTXDetailControllerDelegate, DTXFilterFieldDelegate, DTXPlotControllerSampleClickHandlingDelegate>
{
	__weak IBOutlet NSView* _topView;
	__weak IBOutlet NSPathControl* _pathControl;
	__weak IBOutlet NSTextField* _noSamplesLabel;
	__weak IBOutlet NSView* _bottomViewsContainer;
	__weak IBOutlet NSView* _bottomView;
	__weak IBOutlet DTXFilterField* _searchField;
	
	DTXLogDetailController* _logDetailController;
	
	NSArray<DTXDetailController*>* _cachedDetailControllers;
}

@end

@implementation DTXDetailContentController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	_pathControl.pathItems = @[];
	_pathControl.menu = nil;
	_pathControl.pathStyle = NSPathStyleStandard;
	_pathControl.delegate = self;
	
	_searchField.filterDelegate = self;
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	if(_logDetailController == nil)
	{
		_logDetailController = [self.storyboard instantiateControllerWithIdentifier:@"DTXLogDetailController"];
		[_logDetailController loadProviderWithDocument:self.document];
//		_logDataProvider.delegate = self;
	}
}

- (void)_updateBottomViewVisibility
{
	_bottomView.hidden = _activeDetailController == nil || _activeDetailController.supportsDataFiltering == NO;
	
	NSEdgeInsets insets = NSEdgeInsetsMake(0, 0, _bottomView.hidden ? 0 : _bottomView.bounds.size.height, 0);
	
	[_activeDetailController updateViewWithInsets:insets];
}

- (void)setManagingPlotController:(id<DTXPlotController>)managingPlotController
{
	_managingPlotController.sampleClickDelegate = nil;
	
	_managingPlotController = managingPlotController;
	_cachedDetailControllers = managingPlotController.dataProviderControllers;
	
	_managingPlotController.sampleClickDelegate = self;
	
	[self _activateDetailProviderController:_cachedDetailControllers.firstObject];
}

- (BOOL)_isLogShown
{
	return _logDetailController != nil && _activeDetailController == _logDetailController;
}

- (void)_updatePathControlItems
{
	NSPathControlItem* currentItem = [NSPathControlItem new];
	currentItem.title = _activeDetailController.displayName;
	currentItem.image = _activeDetailController.smallDisplayIcon;
	[[currentItem valueForKey:@"secretCell"] setTextColor:NSColor.labelColor];

	if([_cachedDetailControllers containsObject:_activeDetailController])
	{
		NSPathControlItem* parentItem = [NSPathControlItem new];
		parentItem.title = self.managingPlotController.displayName;
		parentItem.image = self.managingPlotController.smallDisplayIcon;
		[[parentItem valueForKey:@"secretCell"] setTextColor:NSColor.labelColor];

		_pathControl.pathItems = @[parentItem, currentItem];
	}
	else
	{
		_pathControl.pathItems = @[currentItem];
	}
}

- (NSMenu *)_menuForCachedDetailControllersWithFont:(NSFont*)font
{
	NSMenu* menu = [NSMenu new];
	
	[_cachedDetailControllers enumerateObjectsUsingBlock:^(DTXDetailController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMenuItem* item = [NSMenuItem new];
		item.attributedTitle = [[NSAttributedString alloc] initWithString:obj.displayName attributes:font ? @{NSFontAttributeName: font} : @{}];
		item.image = obj.smallDisplayIcon;
		item.state = _activeDetailController == obj;
		item.representedObject = obj;
		item.target = self;
		item.action = @selector(_selectDetailProviderControllerFromMenuItem:);
		[menu addItem:item];
	}];
	
	return menu;
}

- (NSMenu *)pathControl:(NSPathControl *)pathControl menuForCell:(NSPathComponentCell *)cell
{
	NSMenu* menuForCachedDetailControllers = [self _menuForCachedDetailControllersWithFont:cell.font];
	NSUInteger indexOfCell = [[pathControl.cell pathComponentCells] indexOfObject:cell];
	if(indexOfCell == 1)
	{
		return menuForCachedDetailControllers;
	}
	
	NSMenu* menu = [NSMenu new];
	
	NSMenuItem* plotControllerItem = [NSMenuItem new];
	plotControllerItem.attributedTitle = [[NSAttributedString alloc] initWithString:_managingPlotController.displayName attributes:cell.font ? @{NSFontAttributeName: cell.font} : @{}];
	plotControllerItem.image = _managingPlotController.smallDisplayIcon;
//	plotControllerItem.state = [_cachedDetailControllers containsObject:_activeDetailController];
	plotControllerItem.submenu = menuForCachedDetailControllers;
	plotControllerItem.representedObject = _managingPlotController;
	plotControllerItem.target = self;
	plotControllerItem.action = @selector(_selectDetailProviderControllerFromMenuItem:);
	[menu addItem:plotControllerItem];
	
	NSMenuItem* logItem = [NSMenuItem new];
	logItem.attributedTitle = [[NSAttributedString alloc] initWithString:_logDetailController.displayName attributes:cell.font ? @{NSFontAttributeName: cell.font} : @{}];
	logItem.image = _logDetailController.smallDisplayIcon;
	logItem.state = _activeDetailController == _logDetailController;
	logItem.representedObject = _logDetailController;
	logItem.target = self;
	logItem.action = @selector(_selectDetailProviderControllerFromMenuItem:);
	[menu addItem:logItem];
	
	return menu;
}

- (void)_setupConstraintsForMiddleView:(NSView*)view
{
	[NSLayoutConstraint activateConstraints:@[
											  [view.topAnchor constraintEqualToAnchor:_bottomViewsContainer.topAnchor],
											  [view.bottomAnchor constraintEqualToAnchor:_bottomViewsContainer.bottomAnchor],
											  [view.leftAnchor constraintEqualToAnchor:_bottomViewsContainer.leftAnchor],
											  [view.rightAnchor constraintEqualToAnchor:_bottomViewsContainer.rightAnchor],
											  ]];
}

- (void)_setDetailProviderControllerAsMiddleView
{
	_activeDetailController.view.translatesAutoresizingMaskIntoConstraints = NO;
	[_bottomViewsContainer addSubview:_activeDetailController.view positioned:NSWindowBelow relativeTo:_bottomView];
	[self addChildViewController:_activeDetailController];
	[self _setupConstraintsForMiddleView:_activeDetailController.view];
}

- (void)_activateDetailProviderController:(DTXDetailController*)dataProviderController
{
	if(_activeDetailController == dataProviderController)
	{
		return;
	}

	[_activeDetailController.view removeFromSuperview];
	[_activeDetailController removeFromParentViewController];
	_activeDetailController.delegate = nil;
	
	if(dataProviderController == nil)
	{
		_noSamplesLabel.hidden = NO;
		_bottomView.hidden = YES;
	
		return;
	}
	
	_activeDetailController = dataProviderController;
	_activeDetailController.delegate = self;

	_noSamplesLabel.hidden = YES;
	[self _setDetailProviderControllerAsMiddleView];
	
	[self detailController:_activeDetailController didSelectInspectorItem:_activeDetailController.detailDataProvider.currentlySelectedInspectorItem];
	
	[self _updatePathControlItems];
	[self _updateBottomViewVisibility];
}

- (IBAction)_selectDetailProviderControllerFromMenuItem:(NSMenuItem*)sender
{
	if([sender.representedObject isKindOfClass:[DTXDetailController class]])
	{
		[self _activateDetailProviderController:sender.representedObject];
		return;
	}
	
	if(sender.representedObject == _managingPlotController)
	{
		[self _activateDetailProviderController:_cachedDetailControllers.firstObject];
		return;
	}
	
	[self _activateDetailProviderController:_logDetailController];
}

#pragma mark DTXDetailControllerDelegate

- (void)detailController:(DTXDetailController *)detailController didSelectInspectorItem:(DTXInspectorDataProvider *)item
{
	if(detailController != _activeDetailController)
	{
		return;
	}
	
	[self.delegate bottomController:self updateWithInspectorProvider:item];
	
	if(item != nil && [item.sample isKindOfClass:[DTXLogSample class]] == NO)
	{
		[_logDetailController scrollToTimestamp:item.sample.timestamp];
	}
}

#pragma mark DTXFilterFieldDelegate

- (void)filterFieldTextDidChange:(DTXFilterField *)filterField
{
	[_activeDetailController filterSamples:filterField.stringValue];
}

#pragma mark DTXPlotControllerSampleClickHandlingDelegate

- (void)plotController:(id<DTXPlotController>)pc didClickOnSample:(DTXSample *)sample
{
	[_cachedDetailControllers enumerateObjectsUsingBlock:^(DTXDetailController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj selectSample:sample];
	}];
	
	if(sample != nil)
	{
		[_logDetailController scrollToTimestamp:sample.timestamp];
	}
}

@end
