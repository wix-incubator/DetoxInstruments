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
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[_tableView reloadData];
	[_tableView layoutSubtreeIfNeeded];
	
	[self.view setFrame:NSMakeRect(0, 0, self.view.frame.size.width, MIN(640, _tableView.bounds.size.height))];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _managedPlotControllerGroup.plotControllers.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	DTXPlotControllerPickerCellView* cell = [tableView makeViewWithIdentifier:@"DTXPlotControllerPickerCellView" owner:nil];
//	cell.translatesAutoresizingMaskIntoConstraints = NO;
//
//	NSLayoutConstraint* c = [cell.widthAnchor constraintEqualToConstant:357];
//	c.priority = NSLayoutPriorityRequired;
//	c.active = YES;
	
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
		}
		else
		{
			[_managedPlotControllerGroup setPlotControllerVisible:cell.plotController];
		}
	}
}

@end
