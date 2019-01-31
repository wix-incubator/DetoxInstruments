//
//  DTXSampleContainerProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/1/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSampleContainerProxy.h"
#import "NSView+UIAdditions.h"
#import "DTXSample+Additions.h"

@interface DTXSampleContainerProxy () <NSFetchedResultsControllerDelegate>

@end

@implementation DTXSampleContainerProxy
{
	BOOL _updatesExperiencedErrors;
	
	NSMutableArray* _updates;
	NSMutableArray* _inserts;
	
	BOOL _isDataLoaded;
}

@dynamic fetchRequest;

- (instancetype)initWithOutlineView:(NSOutlineView*)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext isRoot:(BOOL)root
{
	self = [super init];
	
	if(self)
	{
		_outlineView = outlineView;
		_root = root;
		_managedObjectContext = managedObjectContext;
	}
	
	return self;
}

- (void)prepareData
{
	NSFetchRequest* fr = self.fetchRequest;
	
	NSArray* sortDescriptors = _outlineView.sortDescriptors;
	if(sortDescriptors.count > 0)
	{
		fr.sortDescriptors = sortDescriptors;
	}
	NSManagedObjectContext* ctx = self.managedObjectContext;
	
	if(fr == nil || ctx == nil)
	{
		return;
	}
	
	_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:ctx sectionNameKeyPath:nil cacheName:nil];
	if(fr.resultType == NSManagedObjectResultType)
	{
		_fetchedResultsController.delegate = self;
	}
	[_fetchedResultsController performFetch:NULL];
}

- (void)reloadData
{
	NSLog(@"😀 %@", self);
	
	[self prepareData];
	
	_isDataLoaded = YES;
}

- (BOOL)isDataLoaded
{
	return _isDataLoaded;
}

- (void)sortWithSortDescriptors:(NSArray<NSSortDescriptor*>*)sortDescriptors
{
	_fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors;
	[_fetchedResultsController performFetch:NULL];
	[_outlineView reloadData];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_updates = [NSMutableArray new];
	_inserts = [NSMutableArray new];
	
	_updatesExperiencedErrors = NO;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if(type == NSFetchedResultsChangeUpdate && [self isObjectIgnoredForUpdates:anObject] == NO)
	{
		[_updates addObject:@{@"anObject": anObject, @"indexPath": indexPath}];
	}
	
	if(type == NSFetchedResultsChangeInsert)
	{
		[_inserts addObject:@{@"anObject": anObject, @"indexPath": newIndexPath}];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	NSRect documentVisibleRect = self.outlineView.enclosingScrollView.contentView.documentVisibleRect;
	CGFloat scrollPoint = NSMaxY(documentVisibleRect);
	
	BOOL shouldScroll = /*_document.documentState = DTXRecordingDocumentStateLiveRecording &&*/ scrollPoint >= NSHeight(self.outlineView.bounds);
	
	[_inserts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:YES]]];
	
	BOOL reloadProxy = NO;
	[self handleSampleInserts:_inserts updates:_updates shouldReloadProxy:&reloadProxy];
	
	if(reloadProxy || _updatesExperiencedErrors)
	{
		[_outlineView reloadItem:self.isRoot ? nil : self reloadChildren:YES];
	}
	
	if(shouldScroll)
	{
		[_outlineView scrollToBottom];
	}
}

- (void)handleSampleInserts:(NSArray*)inserts updates:(NSArray*)updates shouldReloadProxy:(BOOL*)reloadProxy
{
	@try
	{
		[self.outlineView beginUpdates];
		
		[inserts enumerateObjectsUsingBlock:^(NSDictionary* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//			id anObject = obj[@"anObject"];
			NSIndexPath* newIndexPath = obj[@"indexPath"];
			
			[self.outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:newIndexPath.item] inParent:_root ? nil : self withAnimation:NSTableViewAnimationEffectNone];
		}];
		
		[updates enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			NSIndexPath* indexPath = obj[@"indexPath"];
			
			[self.outlineView reloadItem:[self sampleAtIndex:indexPath.item]];
		}];
		
		[self.outlineView endUpdates];
		
		[self.outlineView expandItem:self expandChildren:NO];
	}
	@catch(NSException* e)
	{
		*reloadProxy = YES;
	}
}

- (BOOL)isExpandable
{
	return YES;
}

- (NSUInteger)samplesCount
{
	return _fetchedResultsController.fetchedObjects.count;
}

- (id)sampleAtIndex:(NSUInteger)index
{
	if(index >= _fetchedResultsController.fetchedObjects.count)
	{
		return nil;
	}
	
	id obj = [_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
	
	return [self objectForSample:obj];
}

- (id)objectForSample:(id)sample
{
	return sample;
}

- (BOOL)isObjectIgnoredForUpdates:(id)object
{
	return NO;
}

- (BOOL)wantsStandardGroupDisplay
{
	return NO;
}

@end
