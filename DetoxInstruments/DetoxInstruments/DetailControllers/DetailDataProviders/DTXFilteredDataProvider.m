//
//  DTXFilteredDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXFilteredDataProvider.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXInstrumentsModel.h"

@interface DTXFilteredDataProvider () <NSFetchedResultsControllerDelegate>

@end

@implementation DTXFilteredDataProvider
{
	NSFetchedResultsController* _frc;
	BOOL _updatesExperiencedErrors;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document managedOutlineView:(NSOutlineView*)managedOutlineView sampleTypes:(NSArray<NSNumber *> *)sampleTypes filteredAttributes:(NSArray<NSString *> *)filteredAttributes
{
	self = [super init];
	
	if(self)
	{
		_document = document;
		_managedOutlineView = managedOutlineView;
		_sampleTypes = sampleTypes;
		_filteredAttributes = filteredAttributes;
	}
	
	return self;
}

- (void)filterSamplesWithPredicate:(NSPredicate *)predicate
{
	if(_frc == nil)
	{
		NSParameterAssert(self.sampleTypes.count == 1);
		
		NSFetchRequest* fr = [NSFetchRequest new];
		Class cls = [DTXSample classFromSampleType:self.sampleTypes.firstObject.unsignedIntegerValue];
		NSString* entityName = [NSStringFromClass(cls) substringFromIndex:3];
		fr.entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:_document.recording.managedObjectContext];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		
		_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:_document.recording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		_frc.delegate = self;
	}

	_frc.fetchRequest.predicate = predicate;

	[_frc performFetch:NULL];
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
}


@end
