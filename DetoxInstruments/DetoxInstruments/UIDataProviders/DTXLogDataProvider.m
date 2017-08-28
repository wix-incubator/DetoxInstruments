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
@import ObjectiveC;
#import "DTXLogLineInspectorDataProvider.h"

@interface DTXLogDataProvider() <NSTableViewDataSource, NSTableViewDelegate, NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController<DTXLogSample*>* _frc;
	BOOL _updatesExperiencedErrors;
	BOOL _hasAutomaticRowHeights;
}

@end

@implementation DTXLogDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXLogLineInspectorDataProvider class];
}

+ (NSFont*)fontForObjectDisplay
{
	static NSFont* font;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		font = [NSFont fontWithName:@"SFMono-Regular" size:11];
		
		if(font == nil)
		{
			//There is no SFMono in the system, use Menlo instead.
			font = [NSFont fontWithName:@"Menlo" size:11];
		}
	});
	
	return font;
}

- (instancetype)initWithDocument:(DTXDocument*)document managedTableView:(NSTableView*)tableView
{
	self = [super init];
	
	if(self)
	{
		_document = document;
		_managedTableView = tableView;
		
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
		if (@available(macOS 10.13, *))
		{
			tableView.usesAutomaticRowHeights = YES;
			_hasAutomaticRowHeights = YES;
		}
		else
#endif
		{
			Method m = class_getInstanceMethod(self.class, @selector(__tableView:heightOfRow:));
			BOOL b = class_addMethod(self.class, @selector(tableView:heightOfRow:), method_getImplementation(m), method_getTypeEncoding(m));
			NSLog(@"b = %@", @(b));
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXDocumentStateDidChangeNotification object:self.document];
		
		if(_document.recording != nil)
		{
			[self _prepareLogData];
		}
	}
	
	return self;
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	if(_document.recording != nil)
	{
		[self _prepareLogData];
	}
}

- (void)_prepareLogData
{
	NSFetchRequest* fr = [DTXLogSample fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:_document.recording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	_frc.delegate = self;
	[_frc performFetch:NULL];
	
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

- (CGFloat)__tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSTableColumn *tableColumn = [[tableView tableColumns] objectAtIndex:0];
	NSCell *cell = [tableColumn dataCellForRow:row];
	NSString *content = [_frc.fetchedObjects[row].line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	[cell setObjectValue:content];
	[cell setWraps:YES];
	return [cell cellSizeForBounds:NSMakeRect(0, 0, [tableColumn width], FLT_MAX)].height + 5;
}

- (void)tableViewColumnDidResize:(NSNotification *)notification
{
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
	if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion <= 12)
#endif
	{
		if(_frc.managedObjectContext.persistentStoreCoordinator.persistentStores.count == 0)
		{
			return;
		}
		
		NSIndexSet* selectedRowIndices = _managedTableView.selectedRowIndexes;
		[_managedTableView reloadData];
		[_managedTableView selectRowIndexes:selectedRowIndices byExtendingSelection:NO];
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DTXTextViewCellView* cell = [tableView makeViewWithIdentifier:@"DTXLogEntryCell" owner:nil];
	cell.contentTextField.font = self.class.fontForObjectDisplay;
	cell.contentTextField.stringValue = [_frc.fetchedObjects[row].line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	cell.contentTextField.allowsDefaultTighteningForTruncation = NO;
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
}

#pragma mark DTXWindowWideCopyHanler

- (BOOL)canCopy
{
	return _managedTableView.selectedRowIndexes.count > 0;
}

- (void)copy:(id)sender targetView:(__kindof NSView*)targetView
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

#pragma mark DTXUIDataProvider

- (DTXInspectorDataProvider *)currentlySelectedInspectorItem
{
	if(_managedTableView.selectedRowIndexes.count != 1)
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

- (void)filterSamplesWithFilter:(NSString*)filter;
{
	NSString* _filter = [filter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	_frc.fetchRequest.predicate = _filter.length == 0 ? nil : [NSPredicate predicateWithFormat:@"line CONTAINS[cd] %@", _filter];
	[_frc performFetch:NULL];
	[_managedTableView reloadData];
}

@end
