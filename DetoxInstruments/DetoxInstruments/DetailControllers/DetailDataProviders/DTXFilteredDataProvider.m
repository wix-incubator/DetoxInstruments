//
//  DTXFilteredDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXFilteredDataProvider.h"
#import "DTXInstrumentsModel.h"

@interface DTXFilteredDataProvider () <NSFetchedResultsControllerDelegate>

@end

@implementation DTXFilteredDataProvider
{
	NSFetchedResultsController* _frc;
	BOOL _updatesExperiencedErrors;
	
	NSMutableSet* _filteredObjectIDs;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document managedOutlineView:(NSOutlineView*)managedOutlineView sampleClass:(Class)sampleClass filteredAttributes:(NSArray<NSString*>*)filteredAttributes
{
	self = [super init];
	
	if(self)
	{
		_document = document;
		_managedOutlineView = managedOutlineView;
		_sampleClass = sampleClass;
		_filteredAttributes = filteredAttributes;
	}
	
	return self;
}

- (NSSet<NSManagedObjectID *> *)filteredObjectIDs
{
	return _filteredObjectIDs;
}

- (void)filterSamplesWithPredicate:(NSPredicate *)predicate
{
	_predicate = predicate;
	
	if(_frc == nil)
	{
		NSParameterAssert(self.sampleClass != nil);
		
		NSFetchRequest* fr = [self.sampleClass fetchRequest];
		
		NSArray* sortDescriptors = _managedOutlineView.sortDescriptors;
		if(sortDescriptors.count == 0)
		{
			sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		}
		
		fr.sortDescriptors = sortDescriptors;
		
		_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:_document.firstRecording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		_frc.delegate = self;
	}

	_frc.fetchRequest.predicate = predicate;
	
	NSFetchRequest* fr = [_frc.fetchRequest copy];
	fr.sortDescriptors = nil;
	fr.resultType = NSManagedObjectIDResultType;
	NSArray* objectIDs = [_document.firstRecording.managedObjectContext executeFetchRequest:fr error:NULL];
	_filteredObjectIDs = [NSMutableSet setWithArray:objectIDs];
	
	[self _notifyDelegateOfFilterAfterDelay];

	[_frc performFetch:NULL];
}

- (void)_notifyDelegateOfFilterAfterDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_notifyDelegateOfFilterActual) object:nil];
	[self performSelector:@selector(_notifyDelegateOfFilterActual) withObject:nil afterDelay:0.3];
}

- (void)_notifyDelegateOfFilterActual
{
	[self.delegate filteredDataProviderDidFilter:self];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	return _frc.fetchedObjects.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	if(item != nil)
	{
		return nil;
	}
	
	return [_frc objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
	_frc.fetchRequest.sortDescriptors = outlineView.sortDescriptors;
	[_frc performFetch:NULL];
	[outlineView reloadData];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_updatesExperiencedErrors = NO;
	[_managedOutlineView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if(type != NSFetchedResultsChangeInsert)
	{
		return;
	}
	
	@try
	{
		[_managedOutlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:newIndexPath.item] inParent:nil withAnimation:NSTableViewAnimationEffectNone];
		[_filteredObjectIDs addObject:[anObject objectID]];
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
		[_managedOutlineView endUpdates];
	}
	@catch(NSException* e)
	{
		_updatesExperiencedErrors = YES;
	}
	
	if(_updatesExperiencedErrors)
	{
		[_managedOutlineView reloadData];
	}
	
	[self _notifyDelegateOfFilterAfterDelay];
}


@end
