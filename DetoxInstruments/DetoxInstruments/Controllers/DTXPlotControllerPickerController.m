//
//  DTXPlotControllerPickerController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/12/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotControllerPickerController.h"
#import "DTXPlotControllerPickerCellView.h"

@interface DTXPlotControllerPickerController () <NSTableViewDelegate, NSTableViewDataSource>

@end

@implementation DTXPlotControllerPickerController
{
	IBOutlet NSTableView* _tableView;
	NSUInteger _visibleCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[_tableView reloadData];
	[_tableView layoutSubtreeIfNeeded];
	
	[self.view setFrame:NSMakeRect(0, 0, self.view.frame.size.width, MIN(590, _tableView.bounds.size.height))];
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
	if(_visibleCount == 0)
	{
		[_managedPlotControllerGroup resetPlotControllerVisibility];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _managedPlotControllerGroup.plotControllers.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	DTXPlotControllerPickerCellView* cell = [tableView makeViewWithIdentifier:@"DTXPlotControllerPickerCellView" owner:nil];
	cell.plotControllerEnabled = [_managedPlotControllerGroup isPlotControllerVisible:_managedPlotControllerGroup.plotControllers[row]];
	if(cell.plotControllerEnabled)
	{
		_visibleCount += 1;
	}
	
	[cell setPlotController:_managedPlotControllerGroup.plotControllers[row]];
	
	return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if(_tableView.selectedRow != -1)
	{
		DTXPlotControllerPickerCellView* cell = [_tableView viewAtColumn:0 row:_tableView.selectedRow makeIfNecessary:YES];
		cell.plotControllerEnabled = !cell.plotControllerEnabled;
		[_tableView deselectAll:nil];
		
		if(!cell.plotControllerEnabled)
		{
			[_managedPlotControllerGroup setPlotControllerHidden:cell.plotController];
			_visibleCount -= 1;
		}
		else
		{
			[_managedPlotControllerGroup setPlotControllerVisible:cell.plotController];
			_visibleCount += 1;
		}
	}
}

@end
