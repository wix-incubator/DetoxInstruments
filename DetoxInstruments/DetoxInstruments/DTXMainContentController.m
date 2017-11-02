//
//  DTXMainContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXMainContentController.h"
#import "DTXAxisHeaderPlotController.h"
#import "DTXManagedPlotControllerGroup.h"

#import "DTXCPUUsagePlotController.h"
#import "DTXThreadCPUUsagePlotController.h"
#import "DTXMemoryUsagePlotController.h"
#import "DTXFPSPlotController.h"
#import "DTXDiskReadWritesPlotController.h"
#import "DTXCompactNetworkRequestsPlotController.h"
#import "DTXPlotTableView.h"

#import "DTXRecording+UIExtensions.h"
#import "DTXRNCPUUsagePlotController.h"
#import "DTXRNBridgeCountersPlotController.h"
#import "DTXRNBridgeDataTransferPlotController.h"

@interface DTXMainContentController () <DTXManagedPlotControllerGroupDelegate, NSFetchedResultsControllerDelegate>
{
	__weak IBOutlet DTXPlotTableView *_tableView;
	DTXManagedPlotControllerGroup* _plotGroup;
	__weak IBOutlet NSView *_headerView;
	
	DTXCPUUsagePlotController* _cpuPlotController;
	NSMutableArray<DTXThreadInfo*>* _insertedCPUThreads;
	NSFetchedResultsController* _threadsObserver;
}

@end

@implementation DTXMainContentController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.layer.backgroundColor = NSColor.textBackgroundColor.CGColor;
	
	static const CGFloat inset = 25.0;
	_tableView.enclosingScrollView.contentInsets = NSEdgeInsetsMake(0, 0, inset, 0);
	_tableView.enclosingScrollView.scrollerInsets = NSEdgeInsetsMake(0, 0, -inset, 0);
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self.document readyForRecordingIfNeeded];
	});
	
	[_tableView.window makeFirstResponder:_tableView];
}

- (void)setDocument:(DTXDocument *)document
{
	if(_document)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:DTXDocumentStateDidChangeNotification object:_document];
	}
	
	_document = document;
	
	[self _reloadPlotGroupIfNeeded];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXDocumentStateDidChangeNotification object:_document];
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	_plotGroup = nil;
	
	if(self.document.recording == nil)
	{
		return;
	}
	
	[self _reloadPlotGroupIfNeeded];
}

- (void)_reloadPlotGroupIfNeeded
{
	_headerView.hidden = self.document.documentState == DTXDocumentStateNew;
	
	if(self.document.documentState == DTXDocumentStateNew)
	{
		return;
	}
	
	if(_plotGroup)
	{
		return;
	}
	
	_plotGroup = [[DTXManagedPlotControllerGroup alloc] initWithHostingOutlineView:_tableView];
	_plotGroup.delegate = self;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentDefactoEndTimestampDidChange:) name:DTXDocumentDefactoEndTimestampDidChangeNotification object:self.document];
	
	if(self.document.documentState < DTXDocumentStateLiveRecordingFinished)
	{
		[_plotGroup setGlobalStartTimestamp:self.document.recording.defactoStartTimestamp endTimestamp:[NSDate distantFuture]];
		[_plotGroup setLocalStartTimestamp:self.document.recording.defactoStartTimestamp endTimestamp:[self.document.recording.defactoStartTimestamp dateByAddingTimeInterval:120]];
	}
	else
	{
		[_plotGroup setGlobalStartTimestamp:self.document.recording.defactoStartTimestamp endTimestamp:self.document.recording.defactoEndTimestamp];
		[_plotGroup setLocalStartTimestamp:self.document.recording.defactoStartTimestamp endTimestamp:self.document.recording.defactoEndTimestamp];
	}
	
	_tableView.intercellSpacing = NSMakeSize(0, 1);
	
	DTXAxisHeaderPlotController* headerPlotController = [[DTXAxisHeaderPlotController alloc] initWithDocument:self.document];
	[headerPlotController setUpWithView:_headerView insets:NSEdgeInsetsMake(0, 210, 0, 0)];
	[_plotGroup addHeaderPlotController:headerPlotController];
	
	_cpuPlotController = [[DTXCPUUsagePlotController alloc] initWithDocument:self.document];
	[_plotGroup addPlotController:_cpuPlotController];
	
	NSFetchRequest* fr = [DTXThreadInfo fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]];
	
	_threadsObserver = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.recording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	_threadsObserver.delegate = self;
	[_threadsObserver performFetch:nil];
	
	NSArray* threads = _threadsObserver.fetchedObjects;
	if(threads.count > 0)
	{
		[threads enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[_plotGroup addChildPlotController:[[DTXThreadCPUUsagePlotController alloc] initWithDocument:self.document threadInfo:obj] toPlotController:_cpuPlotController];
		}];
	}
	
	[_plotGroup addPlotController:[[DTXMemoryUsagePlotController alloc] initWithDocument:self.document]];
	[_plotGroup addPlotController:[[DTXFPSPlotController alloc] initWithDocument:self.document]];
	[_plotGroup addPlotController:[[DTXDiskReadWritesPlotController alloc] initWithDocument:self.document]];
	
	if((self.document.recording.dtx_profilingConfiguration == nil || self.document.recording.dtx_profilingConfiguration.recordNetwork == YES))
	{
		[_plotGroup addPlotController:[[DTXCompactNetworkRequestsPlotController alloc] initWithDocument:self.document]];
	}
	
	if(self.document.recording.hasReactNative && self.document.recording.dtx_profilingConfiguration.profileReactNative)
	{
		[_plotGroup addPlotController:[[DTXRNCPUUsagePlotController alloc] initWithDocument:self.document]];
		[_plotGroup addPlotController:[[DTXRNBridgeCountersPlotController alloc] initWithDocument:self.document]];
		[_plotGroup addPlotController:[[DTXRNBridgeDataTransferPlotController alloc] initWithDocument:self.document]];
	}
	
	//This fixes an issue where the main content table does not size correctly.
	NSRect rect = self.view.window.frame;
	rect.size.width += 1;
	[self.view.window setFrame:rect display:NO];
	rect.size.width -= 1;
	[self.view.window setFrame:rect display:NO];
}

- (void)zoomIn
{
	[_plotGroup zoomIn];
}

- (void)zoomOut
{
	[_plotGroup zoomOut];
}

- (void)_documentDefactoEndTimestampDidChange:(NSNotification*)note
{
	if(self.document.documentState < DTXDocumentStateLiveRecordingFinished)
	{
		return;
	}
	
	[_plotGroup setGlobalStartTimestamp:[note.object recording].defactoStartTimestamp endTimestamp:[note.object recording].defactoEndTimestamp];
	[_plotGroup setLocalStartTimestamp:[note.object recording].defactoStartTimestamp endTimestamp:[note.object recording].defactoEndTimestamp];
}

#pragma mark DTXManagedPlotControllerGroupDelegate

- (void)managedPlotControllerGroup:(DTXManagedPlotControllerGroup *)group didSelectPlotController:(id<DTXPlotController>)plotController
{
	[self.delegate contentController:self updateUIWithUIProvider:plotController.dataProvider];
}

#pragma NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_insertedCPUThreads = [NSMutableArray new];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
{
	if(type == NSFetchedResultsChangeInsert)
	{
		[_insertedCPUThreads addObject:anObject];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[_insertedCPUThreads sortUsingDescriptors:controller.fetchRequest.sortDescriptors];
	
	[_insertedCPUThreads enumerateObjectsUsingBlock:^(DTXThreadInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_plotGroup addChildPlotController:[[DTXThreadCPUUsagePlotController alloc] initWithDocument:self.document threadInfo:obj] toPlotController:_cpuPlotController];
	}];
}

@end
