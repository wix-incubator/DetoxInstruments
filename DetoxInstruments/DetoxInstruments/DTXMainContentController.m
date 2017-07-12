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
#import "DTXPlotTypeCellView.h"

#import "DTXCPUUsagePlotController.h"
#import "DTXThreadCPUUsagePlotController.h"
#import "DTXMemoryUsagePlotController.h"
#import "DTXFPSPlotController.h"
#import "DTXDiskReadWritesPlotController.h"
#import "DTXNetworkRequestsPlotController.h"
#import "DTXCompactNetworkRequestsPlotController.h"
#import "DTXAggregatingNetworkRequestsPlotController.h"

#import "DTXRecording+UIExtensions.h"
#import "DTXRNCPUUsagePlotController.h"

@interface DTXMainContentController () <NSTableViewDelegate, NSTableViewDataSource, DTXManagedPlotControllerGroupDelegate>
{
	__weak IBOutlet NSTableView *_tableView;
	DTXManagedPlotControllerGroup* _plotGroup;
	__weak IBOutlet NSView *_headerView;
	
	DTXCPUUsagePlotController* _cpuPlotController;
	NSMutableArray* _threadPlotControllers;
	BOOL _threadsRevealed;
	
	id<DTXPlotController> _currentlySelectedPlotController;
}

@end

@implementation DTXMainContentController

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
	
	DTXDocument* document = (id)self.view.window.windowController.document;
	
	_tableView.intercellSpacing = NSMakeSize(0, 1);
	
	_plotGroup = [[DTXManagedPlotControllerGroup alloc] initWithHostingView:self.view];
	_plotGroup.delegate = self;
	
	DTXAxisHeaderPlotController* headerPlotController = [[DTXAxisHeaderPlotController alloc] initWithDocument:self.view.window.windowController.document];
	[headerPlotController setUpWithView:_headerView insets:NSEdgeInsetsMake(0, 210, 0, 0)];
	[_plotGroup addHeaderPlotController:headerPlotController];
	
	_cpuPlotController = [[DTXCPUUsagePlotController alloc] initWithDocument:self.view.window.windowController.document];
	[_plotGroup addPlotController:_cpuPlotController];
	
	_threadPlotControllers = [NSMutableArray new];
	NSFetchRequest* fr = [DTXThreadInfo fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]];
	NSArray* threads = [[self.view.window.windowController.document recording].managedObjectContext executeFetchRequest:fr error:NULL];
	if(threads.count > 0)
	{
		[threads enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[_threadPlotControllers addObject:[[DTXThreadCPUUsagePlotController alloc] initWithDocument:document threadInfo:obj]];
		}];
	}
	
	[_plotGroup addPlotController:[[DTXMemoryUsagePlotController alloc] initWithDocument:document]];
	[_plotGroup addPlotController:[[DTXFPSPlotController alloc] initWithDocument:document]];
	[_plotGroup addPlotController:[[DTXDiskReadWritesPlotController alloc] initWithDocument:document]];
	
	if((document.recording.dtx_profilingConfiguration == nil || document.recording.dtx_profilingConfiguration.recordNetwork == YES) && document.recording.hasNetworkSamples)
	{
		[_plotGroup addPlotController:[[DTXCompactNetworkRequestsPlotController alloc] initWithDocument:document]];
	}
	
	if(document.recording.hasReactNative && document.recording.dtx_profilingConfiguration.profileReactNative)
	{
		[_plotGroup addPlotController:[[DTXRNCPUUsagePlotController alloc] initWithDocument:document]];
	}
	
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
	
	[_tableView.window makeFirstResponder:_tableView];
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
		DTXPlotTypeCellView* cell = [tableView makeViewWithIdentifier:@"InfoTableViewCell" owner:nil];
		cell.textField.font = controller.titleFont;
		cell.textField.stringValue = controller.displayName;
		cell.textField.toolTip = controller.displayName;
		cell.textField.allowsDefaultTighteningForTruncation = YES;
		cell.imageView.image = controller.displayIcon;
		
		if([controller isMemberOfClass:[DTXCPUUsagePlotController class]] && _threadPlotControllers.count > 0)
		{
			cell.expansionButton.hidden = NO;
			cell.expansionButton.state = _threadsRevealed;
			[cell.expansionButton setTarget:self];
			[cell.expansionButton setAction:@selector(_didExpand)];
		}
		else
		{
			cell.expansionButton.hidden = YES;
		}
		
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

- (void)_didExpand
{
	if(_threadsRevealed == NO)
	{
		[_threadPlotControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[_plotGroup insertPlotController:obj afterPlotController:_cpuPlotController];
		}];
		
		[_tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _threadPlotControllers.count)] withAnimation:NSTableViewAnimationSlideDown];
	}
	else
	{
		[_threadPlotControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[_plotGroup removePlotController:obj];
		}];
		
		[_tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _threadPlotControllers.count)] withAnimation:NSTableViewAnimationSlideUp];
	}
	
   _threadsRevealed = !_threadsRevealed;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return _plotGroup.plotControllers[row].requiredHeight;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return [_plotGroup.plotControllers[row] canReceiveFocus];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[_currentlySelectedPlotController removeHighlight];
	
	id<DTXPlotController> plotController = _plotGroup.plotControllers[_tableView.selectedRowIndexes.firstIndex];
	_currentlySelectedPlotController = plotController;
	
	[self.delegate contentController:self updateUIWithUIProvider:plotController.dataProvider];
}

- (void)managedPlotControllerGroup:(DTXManagedPlotControllerGroup*)group requestPlotControllerSelection:(id<DTXPlotController>)plotController
{
	NSUInteger idx = [group.plotControllers indexOfObject:plotController];
	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
	[_tableView.window makeFirstResponder:_tableView];
}

- (IBAction)zoomIn:(id)sender
{
	[_plotGroup zoomIn];
}

- (IBAction)zoomOut:(id)sender
{
	[_plotGroup zoomOut];
}

@end
