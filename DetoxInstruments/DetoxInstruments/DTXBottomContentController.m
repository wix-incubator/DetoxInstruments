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
#import "NSImage+ImageResize.h"

@interface DTXBottomContentController () <DTXMenuPathControlDelegate, DTXUIDataProviderDelegate>
{
	__weak IBOutlet NSOutlineView *_outlineView;
	__weak IBOutlet NSTableView *_logTableView;
	__weak IBOutlet NSPathControl *_pathControl;
	
	DTXLogDataProvider* _logDataProvider;
	
	BOOL _logShown;
}

@end

@implementation DTXBottomContentController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (@available(macOS 10.13, *)) {
		_logTableView.usesAutomaticRowHeights = YES;
	}
	
	_pathControl.pathItems = @[];
	_pathControl.menu = nil;
	_pathControl.pathStyle = NSPathStyleStandard;
	_pathControl.delegate = self;
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	if(_logDataProvider == nil)
	{
		_logDataProvider = [[DTXLogDataProvider alloc] initWithDocument:self.view.window.windowController.document managedTableView:_logTableView];
	}
}

- (void)setManagingDataProvider:(DTXUIDataProvider *)managingDataProvider
{
	_managingDataProvider.managedOutlineView = nil;
	_managingDataProvider = managingDataProvider;
	_managingDataProvider.managedOutlineView = _outlineView;
	_managingDataProvider.delegate = self;
	
	[self _updatePathControlItems];
}

- (void)_updatePathControlItems
{
	NSPathControlItem* p1 = [NSPathControlItem new];
	p1.image = [NSImage imageNamed: _logShown ? @"console_small" : [NSString stringWithFormat:@"%@_small", _managingDataProvider.displayIcon.name]];
	p1.title = _logShown ? NSLocalizedString(@"Console", @"") : _managingDataProvider.displayName;
	
	if(_logShown == NO)
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

- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
//_outlineView
}

- (NSMenu *)pathControl:(NSPathControl *)pathControl menuForCell:(NSPathComponentCell *)cell
{
	NSUInteger indexOfCell = [[pathControl.cell pathComponentCells] indexOfObject:cell];
	
	NSMenu* m = [NSMenu new];
	NSMenuItem* item1 = [NSMenuItem new];
	item1.attributedTitle = [[NSAttributedString alloc] initWithString: indexOfCell > 0 ? cell.title : _managingDataProvider.displayName attributes: cell.font ? @{NSFontAttributeName: cell.font} : @{}];
	item1.state = _logShown == NO ? NSOnState : NSOffState;
	item1.image = indexOfCell == 0 ? [[NSImage imageNamed:[NSString stringWithFormat:@"%@_small", _managingDataProvider.displayIcon.name]] dtx_imageWithSize:NSMakeSize(16, 16)] : nil;
	item1.target = self;
	item1.action = @selector(_selectManagingDataProvider);
	[m addItem:item1];
	if(indexOfCell == 0)
	{
		NSMenuItem* item2 = [NSMenuItem new];
		item2.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Console", @"") attributes: cell.font ? @{NSFontAttributeName: cell.font} : @{}];
		item2.image = [NSImage imageNamed:@"console_small"];
		item2.state = _logShown ? NSOnState : NSOffState;
		item2.target = self;
		item2.action = @selector(_selectConsole);
		[m addItem:item2];
	}
	
	return m;
}

- (void)_selectManagingDataProvider
{
	_outlineView.superview.superview.hidden = NO;
	_logShown = NO;
	
	[self _updatePathControlItems];
}

- (void)_selectConsole
{
	_outlineView.superview.superview.hidden = YES;
	_logShown = YES;
	
	[self _updatePathControlItems];
}

- (void)dataProvider:(DTXUIDataProvider*)provider didSelectInspectorItem:(DTXInspectorDataProvider*)item
{
	[self.delegate bottomController:self updateWithInspectorProvider:item];
}


@end
