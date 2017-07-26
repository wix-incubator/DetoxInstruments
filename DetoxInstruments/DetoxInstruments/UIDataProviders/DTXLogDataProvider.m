//
//  DTXLogDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXLogDataProvider.h"
#import "DTXTableRowView.h"
#import "DTXTextViewCellView.h"

@interface DTXLogDataProvider() <NSTableViewDataSource, NSTableViewDelegate, NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController<DTXLogSample*>* _frc;
	BOOL _updatesExperiencedErrors;
}

@end

@implementation DTXLogDataProvider

- (instancetype)initWithDocument:(DTXDocument*)document managedTableView:(NSTableView*)tableView
{
	self = [super init];
	
	if(self)
	{
		_document = document;
		_managedTableView = tableView;
		
		if(_document.recording != nil)
		{
			[self _prepareLogData];
		}
	}
	
	return self;
}

- (void)_prepareLogData
{
	NSFetchRequest* fr = [DTXLogSample fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
#if DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
	fr.predicate = [NSPredicate predicateWithFormat:@"parentGroup.recording == %@", self.document.recording];
#endif
	
	_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:_document.recording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	_frc.delegate = self;
	[_frc performFetch:NULL];
	//		_logEntries = [_document.recording.managedObjectContext executeFetchRequest:fr error:NULL];
	
	_managedTableView.dataSource = self;
	_managedTableView.delegate = self;
	
	[_managedTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _frc.fetchedObjects.count;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [DTXTableRowView new];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DTXTextViewCellView* cell = [tableView makeViewWithIdentifier:@"DTXLogEntryCell" owner:nil];
	
	cell.contentTextField.stringValue = [_frc.fetchedObjects[row].line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	cell.contentTextField.allowsDefaultTighteningForTruncation = NO;
	if(NSProcessInfo.processInfo.operatingSystemVersion.minorVersion < 13)
	{
		cell.contentTextField.usesSingleLineMode = YES;
		cell.contentTextField.lineBreakMode = NSLineBreakByTruncatingTail;
	}
	
	return cell;
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
#if DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[fr.predicate, [NSPredicate predicateWithFormat:@"parentGroup.recording == %@", self.document.recording]]];
#endif
	
	DTXLogSample* foundSample = [_document.recording.managedObjectContext executeFetchRequest:fr error:NULL].firstObject;
	
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
	_updatesExperiencedErrors = NO;
	[_managedTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if(type != NSFetchedResultsChangeInsert)
	{
		return;
	}
	
	@try {
		[_managedTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:indexPath.item] withAnimation:NSTableViewAnimationEffectNone];
	}
	@catch(NSException* ex)
	{
		_updatesExperiencedErrors = YES;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	@try {
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
}

@end
