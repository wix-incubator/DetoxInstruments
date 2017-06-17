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

@interface DTXBottomContentController () <NSPathControlDelegate, DTXUIDataProviderDelegate>
{
	__weak IBOutlet NSOutlineView *_outlineView;
	__weak IBOutlet NSTableView *_logTableView;
	__weak IBOutlet NSPathControl *_pathControl;
	
	DTXLogDataProvider* _logDataProvider;
}

@end

@implementation DTXBottomContentController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_pathControl.pathItems = @[];
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
	
	NSPathControlItem* p1 = [NSPathControlItem new];
	p1.image = _managingDataProvider.displayIcon;
	p1.title = _managingDataProvider.displayName;
	
	NSPathControlItem* p2 = [NSPathControlItem new];
	p2.title = NSLocalizedString(@"Samples", @"");
	
	_pathControl.pathItems = @[p1, p2];
}

- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
	
}

- (void)dataProvider:(DTXUIDataProvider*)provider didSelectInspectorItem:(DTXInspectorDataProvider*)item
{
	[self.delegate bottomController:self updateWithInspectorProvider:item];
}


@end
