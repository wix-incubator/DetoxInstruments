//
//  DTXBottomContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXBottomContentController.h"
#import "DTXDocument.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXLogDataProvider.h"
#import "DTXMenuPathControl.h"
#import "DTXFilterField.h"

@interface DTXBottomContentController () <DTXMenuPathControlDelegate, DTXUIDataProviderDelegate, DTXFilterFieldDelegate>
{
	__weak IBOutlet NSOutlineView *_outlineView;
	__weak IBOutlet NSTableView *_logTableView;
	__weak IBOutlet NSPathControl *_pathControl;
	__weak IBOutlet DTXFilterField *_searchField;
	__weak IBOutlet NSView *_bottomView;
	
	DTXLogDataProvider* _logDataProvider;
	
	NSObject<DTXUIDataProvider>* _currentlyShownDataProvider;
	
	NSImage* _consoleAppImage;
}

@end

@implementation DTXBottomContentController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	
	_pathControl.pathItems = @[];
	_pathControl.menu = nil;
	_pathControl.pathStyle = NSPathStyleStandard;
	_pathControl.delegate = self;
	
	_searchField.filterDelegate = self;
	
	__unused NSString* path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.Console"];
	_consoleAppImage = [[NSWorkspace sharedWorkspace] iconForFile:path] ?: [NSImage imageNamed:@"console_small"];
	_consoleAppImage.size = NSMakeSize(16, 16);
	
	[self _selectManagingDataProvider];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	if(_logDataProvider == nil)
	{
		_logDataProvider = [[DTXLogDataProvider alloc] initWithDocument:self.document managedTableView:_logTableView];
		_logDataProvider.delegate = self;
	}
}

- (void)_updateBottomViewVisibility
{
	_bottomView.hidden = [_currentlyShownDataProvider.class conformsToProtocol:@protocol(DTXUIDataFiltering)] && _currentlyShownDataProvider.supportsDataFiltering == NO;
	
	NSEdgeInsets insets = NSEdgeInsetsMake(0, 0, _bottomView.hidden ? 0 : _bottomView.bounds.size.height, 0);
	
	_logTableView.enclosingScrollView.contentInsets = _outlineView.enclosingScrollView.contentInsets = insets;
}

- (void)setManagingDataProvider:(DTXUIDataProvider *)managingDataProvider
{
	_managingDataProvider.managedOutlineView = nil;
	_managingDataProvider = managingDataProvider;
	_managingDataProvider.managedOutlineView = _outlineView;
	_managingDataProvider.delegate = self;
	
	[self _selectDataProvider:_managingDataProvider replaceLog:NO];
}

- (BOOL)_isLogShown
{
	return _logDataProvider != nil && _currentlyShownDataProvider == _logDataProvider;
}

- (void)_updatePathControlItems
{
	NSPathControlItem* p1 = [NSPathControlItem new];
	p1.image = self._isLogShown ? _consoleAppImage : [NSImage imageNamed: [NSString stringWithFormat:@"%@_small", _managingDataProvider.displayIcon.name]];
	p1.title = self._isLogShown ? NSLocalizedString(@"Console", @"") : _managingDataProvider ? _managingDataProvider.displayName : @"";
	
	if(self._isLogShown == NO && _managingDataProvider != nil)
	{
		NSPathControlItem* p2 = [NSPathControlItem new];
		p2.title = NSLocalizedString(@"Samples", @"");
		
		_pathControl.pathItems = @[p1, p2];
	}
	else
	{
		_pathControl.pathItems = @[p1];
	}
}

- (NSMenu *)pathControl:(NSPathControl *)pathControl menuForCell:(NSPathComponentCell *)cell
{
	NSUInteger indexOfCell = [[pathControl.cell pathComponentCells] indexOfObject:cell];
	
	NSMenu* m = [NSMenu new];
	NSMenuItem* item1 = [NSMenuItem new];
	item1.attributedTitle = [[NSAttributedString alloc] initWithString: indexOfCell > 0 ? cell.title : _managingDataProvider.displayName attributes: cell.font ? @{NSFontAttributeName: cell.font} : @{}];
	item1.state = self._isLogShown == NO ? NSOnState : NSOffState;
	item1.image = indexOfCell == 0 ? [NSImage imageNamed:[NSString stringWithFormat:@"%@_small", _managingDataProvider.displayIcon.name]] : nil;
	item1.image.size = NSMakeSize(16, 16);
	item1.target = self;
	item1.action = @selector(_selectManagingDataProvider);
	[m addItem:item1];
	if(indexOfCell == 0)
	{
		NSMenuItem* item2 = [NSMenuItem new];
		item2.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Console", @"") attributes: cell.font ? @{NSFontAttributeName: cell.font} : @{}];
		item2.image = _consoleAppImage;
		item2.state = self._isLogShown ? NSOnState : NSOffState;
		item2.target = self;
		item2.action = @selector(_selectConsole);
		[m addItem:item2];
	}
	
	return m;
}

- (void)_selectDataProvider:(NSObject<DTXUIDataProvider>*)dataProvider replaceLog:(BOOL)replaceLog
{
	if(_currentlyShownDataProvider == dataProvider)
	{
		return;
	}
	
	if(self._isLogShown && replaceLog == NO)
	{
		return;
	}
	
	BOOL isDataProviderLog = dataProvider == _logDataProvider;
	
	_outlineView.superview.superview.hidden = isDataProviderLog;
	_logTableView.superview.superview.hidden = isDataProviderLog == NO;
	
	_currentlyShownDataProvider = dataProvider;
	
	[self dataProvider:_currentlyShownDataProvider didSelectInspectorItem:_currentlyShownDataProvider.currentlySelectedInspectorItem];
	
	[self _updatePathControlItems];
	[self _updateBottomViewVisibility];
	[_searchField clearFilter];
	
	DTXInstrumentsWindowController* controller = self.view.window.windowController;
	
	controller.targetForCopy = isDataProviderLog ? _logTableView : nil;
	controller.handlerForCopy = isDataProviderLog ? _logDataProvider : nil;
}

- (void)_selectManagingDataProvider
{
	[self _selectDataProvider:self.managingDataProvider replaceLog:YES];
	
	[self.view.window makeFirstResponder:_outlineView];
}

- (void)_selectConsole
{
	[self _selectDataProvider:_logDataProvider replaceLog:YES];
	
	[self.view.window makeFirstResponder:_logTableView];
}

#pragma mark DTXUIDataProviderDelegate

- (void)dataProvider:(DTXUIDataProvider*)provider didSelectInspectorItem:(DTXInspectorDataProvider*)item
{
	if(provider != _currentlyShownDataProvider)
	{
		return;
	}
	
	[self.delegate bottomController:self updateWithInspectorProvider:item];
	
	if(item != nil && [item.sample isKindOfClass:[DTXLogSample class]] == NO)
	{
		[_logDataProvider scrollToTimestamp:item.sample.timestamp];
	}
}

#pragma mark DTXFilterFieldDelegate

- (void)filterFieldTextDidChange:(DTXFilterField *)filterField
{
	[_currentlyShownDataProvider filterSamplesWithFilter:filterField.stringValue];
}

@end
