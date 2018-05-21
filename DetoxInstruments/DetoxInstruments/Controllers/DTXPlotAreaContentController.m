//
//  DTXPlotAreaContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPlotAreaContentController.h"
#import "DTXPlotTableView.h"
#import "DTXManagedPlotControllerGroup.h"

#import "DTXAxisHeaderPlotController.h"
#import "DTXCPUUsagePlotController.h"
#import "DTXThreadCPUUsagePlotController.h"
#import "DTXMemoryUsagePlotController.h"
#import "DTXFPSPlotController.h"
#import "DTXDiskReadWritesPlotController.h"
#import "DTXCompactNetworkRequestsPlotController.h"
#import "DTXRNCPUUsagePlotController.h"
#import "DTXRNBridgeCountersPlotController.h"
#import "DTXRNBridgeDataTransferPlotController.h"

#import "DTXRecording+UIExtensions.h"

#import "DTXLayerView.h"

//#define DTX_LIVE_RESIZE_SNAPSHOTTING

@interface DTXPlotAreaContentController () <DTXManagedPlotControllerGroupDelegate, NSFetchedResultsControllerDelegate>
{
	IBOutlet DTXPlotTableView *_tableView;
	DTXManagedPlotControllerGroup* _plotGroup;
	IBOutlet NSView *_headerView;
	
	DTXCPUUsagePlotController* _cpuPlotController;
	NSMutableArray<DTXThreadInfo*>* _insertedCPUThreads;
	NSFetchedResultsController* _threadsObserver;

#ifdef DTX_LIVE_RESIZE_SNAPSHOTTING
	BOOL _wasTableFirstResponder;
//	NSImageView* _headerViewSnapshot;
	NSView* _tableViewSnapshotWrapper;
#endif
}

@end

@implementation DTXPlotAreaContentController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_tableView.enclosingScrollView.contentInsets = NSEdgeInsetsMake(0, 0, 20, 0);
	_tableView.enclosingScrollView.scrollerInsets = NSEdgeInsetsMake(0, 0, -20, 0);
	
	[(DTXLayerView*)self.view setUpdateLayerHandler:^ (NSView* view) {
		view.layer.backgroundColor = NSColor.textBackgroundColor.CGColor;
	}];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self.document readyForRecordingIfNeeded];
	});
	
	[_tableView.window makeFirstResponder:_tableView];
	
#ifdef DTX_LIVE_RESIZE_SNAPSHOTTING
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_windowWillStartLiveResize) name:NSWindowWillStartLiveResizeNotification object:self.view.window];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_windowDidEndLiveResize) name:NSWindowDidEndLiveResizeNotification object:self.view.window];
#endif
}

- (void)viewWillDisappear
{
	[super viewWillDisappear];
	
#ifdef DTX_LIVE_RESIZE_SNAPSHOTTING
	[NSNotificationCenter.defaultCenter removeObserver:self name:NSWindowWillStartLiveResizeNotification object:self.view.window];
	[NSNotificationCenter.defaultCenter removeObserver:self name:NSWindowDidEndLiveResizeNotification object:self.view.window];
#endif
}


#ifdef DTX_LIVE_RESIZE_SNAPSHOTTING
- (void)_windowWillStartLiveResize
{
	_wasTableFirstResponder = self.view.window.firstResponder == _tableView;
	
//	NSBitmapImageRep* headerRep = [_headerView bitmapImageRepForCachingDisplayInRect:_headerView.visibleRect];
//	[_headerView cacheDisplayInRect:_headerView.visibleRect toBitmapImageRep:headerRep];
//
//	NSImage* headerImage = [[NSImage alloc] initWithSize:_headerView.bounds.size];
//	headerImage.capInsets = NSEdgeInsetsMake(0, 209.5, 0, 0);
//	[headerImage addRepresentation:headerRep];
//
//	_headerViewSnapshot = [[NSImageView alloc] initWithFrame:_headerView.frame];
//	_headerViewSnapshot.translatesAutoresizingMaskIntoConstraints = NO;
//	_headerViewSnapshot.imageScaling = NSImageScaleAxesIndependently;
//	_headerViewSnapshot.image = headerImage;
//	[_headerViewSnapshot setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
//	[_headerViewSnapshot setContentCompressionResistancePriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	NSBitmapImageRep* tableRep = [_tableView bitmapImageRepForCachingDisplayInRect:_tableView.bounds];
	[_tableView cacheDisplayInRect:_tableView.bounds toBitmapImageRep:tableRep];
	
	NSImage* tableImage = [[NSImage alloc] initWithSize:_tableView.bounds.size];
	tableImage.capInsets = NSEdgeInsetsMake(0, 209.5, 0, 0);
	[tableImage addRepresentation:tableRep];
	
	NSImageView* tableViewSnapshot = [[NSImageView alloc] initWithFrame:_tableView.bounds];
	tableViewSnapshot.translatesAutoresizingMaskIntoConstraints = NO;
	tableViewSnapshot.imageScaling = NSImageScaleAxesIndependently;
	tableViewSnapshot.image = tableImage;
	[tableViewSnapshot setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
	[tableViewSnapshot setContentCompressionResistancePriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
	[tableViewSnapshot setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
	[tableViewSnapshot setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
	
	_tableViewSnapshotWrapper = [NSView new];
	_tableViewSnapshotWrapper.translatesAutoresizingMaskIntoConstraints = NO;
	[_tableViewSnapshotWrapper addSubview:tableViewSnapshot];
	
//	[_headerView removeFromSuperview];
	[_tableView.enclosingScrollView removeFromSuperview];
	
//	[self.view addSubview:_headerViewSnapshot];
	[self.view addSubview:_tableViewSnapshotWrapper];
	
	[NSLayoutConstraint activateConstraints:@[
//											  [_headerViewSnapshot.topAnchor constraintEqualToAnchor:self.view.topAnchor],
//											  [_headerViewSnapshot.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
//											  [_headerViewSnapshot.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
//											  [_headerViewSnapshot.heightAnchor constraintEqualToConstant:_headerView.bounds.size.height],
											  
											  [_tableViewSnapshotWrapper.topAnchor constraintEqualToAnchor:tableViewSnapshot.topAnchor constant:_tableView.enclosingScrollView.contentView.bounds.origin.y],
											  [_tableViewSnapshotWrapper.leadingAnchor constraintEqualToAnchor:tableViewSnapshot.leadingAnchor],
											  [_tableViewSnapshotWrapper.trailingAnchor constraintEqualToAnchor:tableViewSnapshot.trailingAnchor],

											  [_tableViewSnapshotWrapper.topAnchor constraintEqualToAnchor:_headerView.bottomAnchor],
											  [_tableViewSnapshotWrapper.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
											  [_tableViewSnapshotWrapper.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
											  [_tableViewSnapshotWrapper.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
											  ]];
}

- (void)_windowDidEndLiveResize
{
//	[_headerViewSnapshot removeFromSuperview];
//	_headerViewSnapshot = nil;
	
	[_tableViewSnapshotWrapper removeFromSuperview];
	_tableViewSnapshotWrapper = nil;
	
	[self.view addSubview:_headerView];
	[self.view addSubview:_tableView.enclosingScrollView];
	
	[NSLayoutConstraint activateConstraints:@[
											  [_headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
											  [_headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
											  [_headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
											  
											  [_tableView.enclosingScrollView.topAnchor constraintEqualToAnchor:_headerView.bottomAnchor],
											  [_tableView.enclosingScrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
											  [_tableView.enclosingScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
											  [_tableView.enclosingScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
											  ]];
	
	[_tableView setNeedsDisplay];
	
	if(_wasTableFirstResponder)
	{
		[self.view.window makeFirstResponder:_tableView];
	}
}
#endif

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
	[headerPlotController setUpWithView:_headerView insets:NSEdgeInsetsMake(0, 209.5, 0, 0)];
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

- (void)fitAllData
{
	[_plotGroup zoomToFitAllData];
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
	[self.delegate contentController:self updatePlotController:plotController];
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
