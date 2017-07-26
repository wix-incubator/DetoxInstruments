//
//  DTXPerformanceSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPerformanceSamplePlotController.h"
#import "DTXPerformanceSample+CoreDataClass.h"

@interface DTXPerformanceSamplePlotController () <NSFetchedResultsControllerDelegate>
{
	NSMutableArray<NSFetchedResultsController*>* _frcs;
	NSMutableArray<NSNumber*>* _insertions;
	NSMutableArray<NSNumber*>* _updates;
}

@end

@implementation DTXPerformanceSamplePlotController

- (instancetype)initWithDocument:(DTXDocument*)document
{
	self = [super initWithDocument:document];
	
	if(self)
	{
		_frcs = [NSMutableArray new];
	}
	
	return self;
}

- (void)prepareSamples
{
	if(self.document == nil)
	{
		return;
	}
		
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sampleKey, NSUInteger idx, BOOL * _Nonnull stop) {
		NSFetchRequest* fr = [self.classForPerformanceSamples fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		fr.predicate = self.predicateForPerformanceSamples;
#if DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
		fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[fr.predicate, [NSPredicate predicateWithFormat:@"parentGroup.recording == %@", self.document.recording]]];
#endif
		
		NSFetchedResultsController* frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.recording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		frc.delegate = self;
		_frcs[idx] = frc;
		
		NSError* error = nil;
		if([frc performFetch:&error] == NO)
		{
			*stop = YES;
			return;
		}
		NSArray* results = frc.fetchedObjects;
	}];
}

- (NSArray*)samplesForPlotIndex:(NSUInteger)index
{
	return _frcs[index].fetchedObjects;
}

- (NSPredicate*)predicateForPerformanceSamples
{
	return [NSPredicate predicateWithFormat:@"NOT(sampleType IN %@)", @[@(DTXSampleTypeThreadPerformance)]];
}

- (Class)classForPerformanceSamples
{
	return [DTXPerformanceSample class];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_insertions = [NSMutableArray new];
	_updates = [NSMutableArray new];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
{
	if(type == NSFetchedResultsChangeInsert)
	{
		[_insertions addObject:@(newIndexPath.item)];
	}
	else if(type == NSFetchedResultsChangeUpdate)
	{
		[_updates addObject:@(indexPath.item)];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	NSUInteger index = [_frcs indexOfObject:controller];
	[self noteOfSampleInsertions:_insertions updates:_updates forPlotAtIndex:index];
	_insertions = nil;
	_updates = nil;
}

@end
