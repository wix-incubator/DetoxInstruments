//
//  DTXIntervalSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/20/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXIntervalSamplePlotController.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXRangePlotView.h"
#import "DTXFilteredDataProvider.h"
#import "DTXSamplePlotController-Private.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXSampleContainerProxy.h"
#endif
#import "DTXMeasurements.h"
#import "DTXIntervalSectionSamplePlotController.h"
#import "DTXRecording+UIExtensions.h"

#import "DTXLogging.h"
DTX_CREATE_LOG(IntervalSamplePlotController)

//@import os.signpost;

@interface DTXIntervalSamplePlotController () <DTXRangePlotViewDelegate, NSFetchedResultsControllerDelegate, DTXFilteredDataProviderDelegate>
{
	NSFetchedResultsController<DTXSample*>* _frc;
	
	NSMutableArray<DTXRangePlotView*>* _plotViews;
	NSMutableArray<DTXIntervalSectionSamplePlotController*>* _sectionControllers;
	
	DTXFilteredDataProvider* _filteredDataProvider;
	
	BOOL _didAddSection;
}

@end

@implementation DTXIntervalSamplePlotController

+ (Class)classForIntervalSamples
{
	return nil;
}

- (NSPredicate*)predicateForPerformanceSamples
{
	return nil;
}

- (BOOL)includeSeparatorsInStackView
{
	return YES;
}

- (instancetype)initWithDocument:(DTXRecordingDocument *)document isForTouchBar:(BOOL)isForTouchBar
{
	return [self _initWithDocument:document isForTouchBar:isForTouchBar sectionConfigurator:nil];
}

- (instancetype)_initWithDocument:(DTXRecordingDocument*)document isForTouchBar:(BOOL)isForTouchBar sectionConfigurator:(void(^)(void))configurator
{
	self = [super initWithDocument:document isForTouchBar:isForTouchBar];
	
	if(self)
	{
		_plotViews = [NSMutableArray new];
		_sectionControllers = [NSMutableArray new];
		
		if(configurator)
		{
			configurator();
		}
		
		self.plotStackView.distribution = NSStackViewDistributionGravityAreas;
		
		[self _reloadData];
	}
	
	return self;
}

- (void)_reloadData
{
	NSFetchRequest* fr = [self.class.classForIntervalSamples fetchRequest];
	fr.propertiesToFetch = self.propertiesToFetch;
	fr.relationshipKeyPathsForPrefetching = self.relationshipsToFetch;
	fr.predicate = self.predicateForPerformanceSamples;
	
	NSMutableArray* sortDescriptors = (self.sortDescriptors ?: @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]).mutableCopy;
	if(self.isForTouchBar == NO && self.sectionKeyPath != nil)
	{
		[sortDescriptors insertObject:[NSSortDescriptor sortDescriptorWithKey:self.sectionKeyPath ascending:YES] atIndex:0];
	}
	
	fr.sortDescriptors = sortDescriptors;
	
	_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.viewContext sectionNameKeyPath:self.isForTouchBar ? nil : self.sectionKeyPath cacheName:nil];
	_frc.delegate = self;
	NSError* error;
	[_frc performFetch:&error];
	
	[_plotViews removeAllObjects];
	[_sectionControllers removeAllObjects];
	
	[_frc.sections enumerateObjectsUsingBlock:^(id<NSFetchedResultsSectionInfo>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		auto sectionController = [[DTXIntervalSectionSamplePlotController alloc] initWithIntervalSamplePlotController:self fetchedResultsController:_frc isForTouchBar:self.isForTouchBar];
		sectionController.section = idx;
		[sectionController reloadData];
		[_plotViews addObject:sectionController.plotView];
		[_sectionControllers addObject:sectionController];
	}];
}

- (BOOL)usesInternalPlots
{
	return YES;
}

- (void)updateLayerHandler
{
	[_plotViews makeObjectsPerformSelector:@selector(reloadData)];
	
	[super updateLayerHandler];
}

- (BOOL)wantsGestureRecognizerForPlots
{
	return YES;
}

- (void)mouseMoved:(NSEvent *)event
{
	
}

- (DTXPlotRange*)plotRangeForSample:(DTXSample*) sample
{
	NSTimeInterval timestamp =  sample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	NSTimeInterval responseTimestamp = [self endTimestampForSample:sample].timeIntervalSinceReferenceDate  - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	return [DTXPlotRange plotRangeWithPosition:timestamp length:responseTimestamp - timestamp];
}

- (id)_sectionForSample:(DTXSample*)sample
{
	id section;
	if(self.isForTouchBar || self.sectionKeyPath == nil)
	{
		section = @0;
	}
	else
	{
		section = [sample valueForKeyPath:self.sectionKeyPath];
	}
	
	return section;
}

- (void)highlightSample:(DTXSample*)sample
{
	[super highlightSample:sample];
	
#if ! PROFILER_PREVIEW_EXTENSION
	if([sample isKindOfClass:DTXSampleContainerProxy.class])
	{
		return;
	}
#endif
	
	[_sectionControllers[[_frc indexPathForObject:sample].section] highlightSample:sample];
}

- (void)_removeHighlightNotifyingDelegate:(BOOL)notify
{
	[_sectionControllers enumerateObjectsUsingBlock:^(DTXIntervalSectionSamplePlotController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj removeHighlight];
	}];
	
	[super _removeHighlightNotifyingDelegate:notify];
}

- (NSString *)sectionKeyPath
{
	return nil;
}

- (void)invalidateSections;
{
	[self _removeHighlightNotifyingDelegate:YES];
	
	[self _reloadData];
	[self reloadPlotViews];
}

- (NSEdgeInsets)rangeInsets
{
	if(self.isForTouchBar)
	{
		return NSEdgeInsetsZero;
	}
	
	return NSEdgeInsetsMake(5, 0, 5, 0);
}

- (NSDate*)endTimestampForSample:(DTXSample*)sample
{
	return nil;
}

- (NSColor*)colorForSample:(DTXSample*)sample
{
	return nil;
}

- (NSString*)titleForSample:(__kindof DTXSample*)sample
{
	return nil;
}

- (NSArray<NSSortDescriptor *> *)sortDescriptors
{
	return nil;
}

@synthesize filteredDataProvider;
- (void)setFilteredDataProvider:(DTXFilteredDataProvider *)filteredDataProvider
{
	if(_filteredDataProvider == filteredDataProvider)
	{
		return;
	}
	
	_filteredDataProvider = filteredDataProvider;
	_filteredDataProvider.delegate = self;
	
	[_sectionControllers enumerateObjectsUsingBlock:^(DTXIntervalSectionSamplePlotController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj setFilteredDataProvider:filteredDataProvider];
	}];
}

- (void)_resetAfterFilter
{
	[self removeHighlight];
	
	[_sectionControllers enumerateObjectsUsingBlock:^(DTXIntervalSectionSamplePlotController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj resetAfterFilter];
	}];
}

#pragma mark DTXFilteredDataProviderDelegate

- (void)filteredDataProviderDidFilter:(DTXFilteredDataProvider*)fdp
{
	[self _resetAfterFilter];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_didAddSection = NO;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	NSParameterAssert(type == NSFetchedResultsChangeInsert);
	
	for(NSUInteger idx = sectionIndex; idx < _sectionControllers.count; idx++)
	{
		auto sectionController = _sectionControllers[idx];
		sectionController.section++;
	}
	
	auto sectionController = [[DTXIntervalSectionSamplePlotController alloc] initWithIntervalSamplePlotController:self fetchedResultsController:_frc isForTouchBar:self.isForTouchBar];
	sectionController.section = sectionIndex;
	[_plotViews insertObject:sectionController.plotView atIndex:sectionIndex];
	[_sectionControllers insertObject:sectionController atIndex:sectionIndex];
	
	_didAddSection = YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[_sectionControllers makeObjectsPerformSelector:@selector(reloadData)];
	
	if(_didAddSection)
	{
		[self reloadPlotViews];
	}
}

#pragma mark Internal Plots

- (NSArray<DTXPlotView *> *)plotViews
{
	return _plotViews;
}

#pragma mark DTXRangePlotViewDelegate

- (void)plotViewIntrinsicContentSizeDidChange:(DTXPlotView *)plotView
{
	[NSNotificationCenter.defaultCenter postNotificationName:DTXPlotControllerRequiredHeightDidChangeNotification object:self];
}

- (CGFloat)requiredHeight
{
	CGFloat height = self.plotStackView.fittingSize.height;
	
	return MAX(height, super.requiredHeight);
}

- (void)plotView:(DTXRangePlotView *)plotView didClickRangeAtIndex:(NSUInteger)idx
{
	if(self.isForTouchBar)
	{
		return;
	}
	
	if(self.canReceiveFocus == NO)
	{
		return;
	}
	
	[self.delegate plotControllerUserDidClickInPlotBounds:self];
	
	if(idx == NSNotFound)
	{
		[self removeHighlight];
		[self.sampleClickDelegate plotController:self didClickOnSample:nil];
	}
	else
	{
		DTXSample* sample = [_sectionControllers[plotView.plotIndex] sampleAtRangeIndex:idx];
		
		if(_filteredDataProvider && [_filteredDataProvider.filteredObjectIDs containsObject:sample.objectID] == NO)
		{
			return;
		}
		
		[self highlightSample:sample];
		[self.sampleClickDelegate plotController:self didClickOnSample:sample];
	}
}

@end
