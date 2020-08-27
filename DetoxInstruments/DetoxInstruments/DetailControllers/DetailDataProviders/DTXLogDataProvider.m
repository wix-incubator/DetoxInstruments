//
//  DTXLogDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXLogDataProvider.h"
#import "DTXTableRowView.h"
#import "DTXTextViewCellView.h"
@import ObjectiveC;
#import "DTXLogLineInspectorDataProvider.h"
#import "NSView+UIAdditions.h"
#import "DTXFilteredDataProvider.h"
#import "NSFont+UIAdditions.h"
#import "DTXLogSample+UIExtensions.h"

@interface DTXLogDataProvider() <NSTableViewDataSource, NSTableViewDelegate, NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController<DTXLogSample*>* _frc;
	BOOL _updatesExperiencedErrors;
	BOOL _shouldScrollToBottom;
}

@end

@implementation DTXLogDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXLogLineInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return nil;
}

+ (NSFont*)fontForObjectDisplay
{
	static NSFont* font;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		font = [NSFont monospacedSystemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightRegular];
	});
	
	return font;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document
{
	self = [super init];
	
	if(self)
	{
		_document = document;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXRecordingDocumentStateDidChangeNotification object:self.document];
	}
	
	return self;
}

- (void)setManagedTableView:(NSTableView *)managedTableView
{
	_managedTableView = managedTableView;
	_managedTableView.usesAutomaticRowHeights = YES;
	[_managedTableView layoutSubtreeIfNeeded];
	
	if(_document.recordings.count != 0)
	{
		[self _prepareLogData];
	}
	
	if(_document.documentState == DTXRecordingDocumentStateLiveRecording)
	{
		[_managedTableView scrollToBottom];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_managedTableView scrollToBottom];
		});
	}
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	if(_document.recordings.count != 0)
	{
		[self _prepareLogData];
	}
	
//	if(_document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		_managedTableView.usesAutomaticRowHeights = YES;
	}
}

- (NSPredicate*)_defaultLogPredicate
{
	return [NSPredicate predicateWithFormat:@"timestamp > %@", _document.firstRecording.startTimestamp];
}

- (void)_prepareLogData
{
	NSFetchRequest* fr = [DTXLogSample fetchRequest];
	fr.predicate = self._defaultLogPredicate;
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:_document.viewContext sectionNameKeyPath:nil cacheName:nil];
	_frc.delegate = self;
	[_frc performFetch:NULL];
	
	_managedTableView.dataSource = self;
	_managedTableView.delegate = self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _frc.fetchedObjects.count;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	if(row >= _frc.fetchedObjects.count)
	{
		return nil;
	}
	
	DTXTableRowView* rv = [DTXTableRowView new];
	
	rv.userNotifyColor = _frc.fetchedObjects[row].colorForLogLevel;
	
	return rv;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if(row >= _frc.fetchedObjects.count)
	{
		return nil;
	}
	
	if([tableColumn.identifier isEqualToString:@"DTXTypeColumn"])
	{
		return nil;
	}
	
	DTXLogSample* logSample = _frc.fetchedObjects[row];
	
	DTXTextViewCellView* cell = [tableView makeViewWithIdentifier:@"DTXLogEntryCell" owner:nil];
	cell.contentTextField.font = self.class.fontForObjectDisplay;
	cell.contentTextField.allowsDefaultTighteningForTruncation = NO;
	
	if([tableColumn.identifier isEqualToString:@"DTXTimestampColumn"])
	{
		NSDate* timestamp = logSample.timestamp;
		NSTimeInterval ti = [timestamp timeIntervalSinceReferenceDate] - [_document.firstRecording.startTimestamp timeIntervalSinceReferenceDate];
		cell.contentTextField.stringValue = [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)];
	}
	
	if([tableColumn.identifier isEqualToString:@"DTXSubsystemColumn"])
	{
		cell.contentTextField.stringValue = logSample.subsystem ?: @"";
	}
	
	if([tableColumn.identifier isEqualToString:@"DTXCategoryColumn"])
	{
		cell.contentTextField.stringValue = logSample.category ?: @"";
	}
	
	if([tableColumn.identifier isEqualToString:@"DTXMessageColumn"])
	{
		cell.contentTextField.stringValue = logSample.line ?: @"";
	}
	
	return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self.delegate dataProvider:self didSelectInspectorItem:self.currentlySelectedInspectorItem];
}

- (void)scrollToTimestamp:(NSDate*)timestamp
{
	if(timestamp == nil)
	{
		return;
	}
	
	NSFetchRequest* fr = [DTXLogSample fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
	fr.fetchLimit = 1;
	fr.predicate = [NSPredicate predicateWithFormat:@"timestamp < %@", timestamp];
	
	DTXLogSample* foundSample = [_document.viewContext executeFetchRequest:fr error:NULL].firstObject;
	
	if(foundSample == nil)
	{
		return;
	}
	
	NSUInteger idx = [_frc indexPathForObject:foundSample].item;
	
	[_managedTableView scrollRowToVisible:idx];
	
	[_managedTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
	
	//Do it a second time to "fix" potential scroll inaccuracy due to automatic cell height
	[_managedTableView scrollRowToVisible:idx];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	NSRect documentVisibleRect = _managedTableView.enclosingScrollView.contentView.documentVisibleRect;
	CGFloat scrollPoint = NSMaxY(documentVisibleRect);
	
	_shouldScrollToBottom = _document.documentState == DTXRecordingDocumentStateLiveRecording && scrollPoint >= NSHeight(_managedTableView.bounds);
	
	_updatesExperiencedErrors = NO;
	[_managedTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if(_updatesExperiencedErrors == YES)
	{
		return;
	}
	
	if(type != NSFetchedResultsChangeInsert)
	{
		return;
	}
	
	@try
	{
		[_managedTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndexPath.item] withAnimation:NSTableViewAnimationEffectNone];
	}
	@catch(NSException* ex)
	{
		_updatesExperiencedErrors = YES;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	@try
	{
		[_managedTableView endUpdates];
	}
	@catch(NSException* e)
	{
		_updatesExperiencedErrors = YES;
	}
	
	if(_updatesExperiencedErrors)
	{
		[_managedTableView reloadData];
	}
	
	if(_shouldScrollToBottom)
	{
		[_managedTableView scrollToBottom];
	}
}

#pragma mark DTXWindowWideCopyHanler

- (BOOL)canCopy
{
	return _managedTableView.selectedRowIndexes.count > 0;
}

- (void)copy:(id)sender
{
	NSMutableString* stringToCopy = [NSMutableString new];
	
	[_managedTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
		DTXLogSample* logSample = [_frc objectAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
		[stringToCopy appendString:[logSample.line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
		[stringToCopy appendString:@"\n"];
	}];
	
	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:[stringToCopy stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] forType:NSPasteboardTypeString];
}

#pragma mark DTXDetailDataProvider

- (DTXInspectorDataProvider *)currentlySelectedInspectorItem
{
	if(_managedTableView.selectedRowIndexes.count != 1 || _managedTableView.selectedRow >= _frc.fetchedObjects.count)
	{
		return nil;
	}
	
	id item = [_frc objectAtIndexPath:[NSIndexPath indexPathForItem:_managedTableView.selectedRow inSection:0]];
	DTXInspectorDataProvider* idp = [[[self.class inspectorDataProviderClass] alloc] initWithSample:item document:_document];
	
	return idp;
}

#pragma mark DTXUIDataFiltering

- (BOOL)supportsDataFiltering
{
	return YES;
}

- (NSPredicate *)predicateForFilter:(NSString *)filter
{
	return filter.length == 0 ? self._defaultLogPredicate : [NSPredicate predicateWithFormat:@"category CONTAINS[cd] %@ || subsystem CONTAINS[cd] %@ || line CONTAINS[cd] %@", filter, filter, filter];
}

- (void)filterSamplesWithFilter:(NSString*)filter;
{
	NSString* _filter = [filter stringByTrimmingWhiteSpace];
	
	_frc.fetchRequest.predicate = [self predicateForFilter:_filter];
	[_frc performFetch:NULL];
	[_managedTableView reloadData];
}

@end
