//
//  DTXMainContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXMainContentController.h"
#import "DTXAxisHeaderPlotController.h"
#import "DTXPlotHostingTableCellView.h"
#import "DTXTableRowView.h"
#import "DTXManagedPlotControllerGroup.h"

#import "DTXCPUUsagePlotController.h"
#import "DTXMemoryUsagePlotController.h"
#import "DTXFPSPlotController.h"
#import "DTXDiskReadWritesPlotController.h"
#import "DTXNetworkRequestsPlotController.h"
#import "DTXCompactNetworkRequestsPlotController.h"
#import "DTXAggregatingNetworkRequestsPlotController.h"

@interface DTXMainContentController () <NSTableViewDelegate, NSTableViewDataSource>
{
	__weak IBOutlet NSTableView *_tableView;
	DTXManagedPlotControllerGroup* _plotGroup;
	__weak IBOutlet NSView *_headerView;
}

@end

@implementation DTXMainContentController
{
	
}

- (void)viewDidLayout
{
	[super viewDidLayout];
	
	//[self.view addSubview:_headerView positioned:NSWindowAbove relativeTo:_tableView];
	[_plotGroup hostingViewDidLayout];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	if(_plotGroup)
	{
		return;
	}
	
	_tableView.intercellSpacing = NSMakeSize(0, 1);
	
	_plotGroup = [[DTXManagedPlotControllerGroup alloc] initWithHostingView:self.view];
	
	DTXAxisHeaderPlotController* headerPlotController = [[DTXAxisHeaderPlotController alloc] initWithDocument:self.view.window.windowController.document];
	[headerPlotController setUpWithView:_headerView insets:NSEdgeInsetsMake(0, 179, 0, 0)];
	[_plotGroup addHeaderPlotController:headerPlotController];
	
	[_plotGroup addPlotController:[[DTXCPUUsagePlotController alloc] initWithDocument:self.view.window.windowController.document]];
	[_plotGroup addPlotController:[[DTXMemoryUsagePlotController alloc] initWithDocument:self.view.window.windowController.document]];
	[_plotGroup addPlotController:[[DTXFPSPlotController alloc] initWithDocument:self.view.window.windowController.document]];
	[_plotGroup addPlotController:[[DTXDiskReadWritesPlotController alloc] initWithDocument:self.view.window.windowController.document]];
//	[_plotGroup addPlotController:[[DTXNetworkRequestsPlotController alloc] initWithDocument:self.view.window.windowController.document]];
	[_plotGroup addPlotController:[[DTXCompactNetworkRequestsPlotController alloc] initWithDocument:self.view.window.windowController.document]];
	[_plotGroup addPlotController:[[DTXAggregatingNetworkRequestsPlotController alloc] initWithDocument:self.view.window.windowController.document]];
	
	[_tableView reloadData];
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	NSRect rect = self.view.window.frame;
	rect.size.width += 1;
	[self.view.window setFrame:rect display:NO];
	rect.size.width -= 1;
	[self.view.window setFrame:rect display:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _plotGroup.plotControllers.count;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [DTXTableRowView new];
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	id<DTXPlotController> controller = _plotGroup.plotControllers[row];
	
	if([tableColumn.identifier isEqualToString:@"DTXTitleColumnt"])
	{
		NSTableCellView* cell = [tableView makeViewWithIdentifier:@"InfoTableViewCell" owner:nil];
		cell.textField.stringValue = controller.displayName;
		cell.imageView.image = controller.displayIcon;
		return cell;
	}
	else if([tableColumn.identifier isEqualToString:@"DTXGraphColumn"])
	{
		DTXPlotHostingTableCellView* cell = [tableView makeViewWithIdentifier:@"PlotHostingTableViewCell" owner:nil];
		cell.plotController = controller;
		return cell;
	}
	
	return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return _plotGroup.plotControllers[row].requiredHeight;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	id<DTXPlotController> plotController = _plotGroup.plotControllers[_tableView.selectedRowIndexes.firstIndex];
	
	[self.delegate contentController:self updateUIWithUIProvider:plotController.dataProvider];
}

@end
