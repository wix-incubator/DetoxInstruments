//
//  DTXIntervalSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/20/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXIntervalSamplePlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXCPTRangePlot.h"
#import "DTXLineLayer.h"
#import "DTXRecording+UIExtensions.h"
#import "NSFormatter+PlotFormatters.h"
#import "NSColor+UIAdditions.h"
#import "NSAppearance+UIAdditions.h"
#import <LNInterpolation/Color+Interpolation.h>
#import "DTXRangePlotView.h"
#import "DTXFilteredDataProvider.h"
#import "DTXSamplePlotController-Private.h"
#import "DTXSampleContainerProxy.h"
#import "DTXMeasurements.h"

#import "DTXLogging.h"
DTX_CREATE_LOG(IntervalSamplePlotController)

//@import os.signpost;

@interface _DTXSampleGroup : NSObject

@property (nonatomic, strong) NSMutableArray<DTXSample*>* samples;
@property (nonatomic, strong) NSDate* lastDate;

@end

@implementation _DTXSampleGroup

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_samples = [NSMutableArray new];
	}
	
	return self;
}

@end

@interface DTXIntervalSamplePlotController () <DTXRangePlotViewDelegate, DTXRangePlotViewDataSource, NSFetchedResultsControllerDelegate, DTXFilteredDataProviderDelegate>
{
	NSFetchedResultsController<DTXSample*>* _frc;
	
	DTXRangePlotView* _plotView;
	
	NSMutableArray<_DTXSampleGroup*>* _mergedSamples;
	NSMutableArray<NSIndexPath*>* _sampleIndices;
	NSMapTable<NSString*, NSIndexPath*>* _sampleMapping;
	NSMapTable<NSIndexPath*, NSNumber*>* _indexPathIndexMapping;
	NSUInteger _selectedIndex;
	
	DTXFilteredDataProvider* _filteredDataProvider;
}
@end

@implementation DTXIntervalSamplePlotController

+ (Class)classForIntervalSamples
{
	return nil;
}

- (instancetype)initWithDocument:(DTXRecordingDocument *)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super initWithDocument:document isForTouchBar:isForTouchBar];
	
	if(self)
	{
		_selectedIndex = NSNotFound;
	}
	
	return self;
}

- (void)dealloc
{
	if(_plotView)
	{
		[NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"DTXPlotSettingsDisplayLabels"];
	}
}

- (BOOL)usesInternalPlots
{
	return YES;
}

- (void)updateLayerHandler
{
	[_plotView reloadData];
	
	[super updateLayerHandler];
}

- (void)prepareSamples
{
	if(_frc != nil)
	{
		return;
	}
	
	NSFetchRequest* fr = [self.class.classForIntervalSamples fetchRequest];
	fr.propertiesToFetch = self.propertiesToFetch;
	fr.relationshipKeyPathsForPrefetching = self.relationshipsToFetch;
	fr.sortDescriptors = self.sortDescriptors ?: @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.firstRecording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	_frc.delegate = self;
	[_frc performFetch:NULL];
	
	[self _prepareMergedSamples];
	
	[_plotView reloadData];
}

- (NSMutableArray<_DTXSampleGroup*>*)_mergedSamples
{
	[self prepareSamples];
	
	return _mergedSamples;
}

- (NSArray *)samplesForPlotIndex:(NSUInteger)index
{
	return [_frc fetchedObjects];
}

- (void)_prepareMergedSamples
{
	_mergedSamples = [NSMutableArray new];
	_sampleIndices = [NSMutableArray new];
	_sampleMapping = [NSMapTable strongToStrongObjectsMapTable];
	_indexPathIndexMapping = [NSMapTable strongToStrongObjectsMapTable];
	
	if(_frc.fetchedObjects.count == 0)
	{
		return;
	}
	
//	os_log_t log = os_log_create("DetoxInstruments", NSStringFromClass(self.class).UTF8String);
//	os_signpost_id_t signpost_id = os_signpost_id_generate(log);
//
//	os_signpost_interval_begin(log, signpost_id, "_prepareMergedSamples");
//
	DTXStartTimeMeasurment();

	for(DTXSample* currentSample in _frc.fetchedObjects)
	{
		NSDate* timestamp = currentSample.timestamp;
		
		__block _DTXSampleGroup* _insertionGroup = nil;
		
		NSUInteger insertionGroupIndex = 0;
		for (_DTXSampleGroup* possibleSampleGroup in _mergedSamples)
		{
			NSDate* lastResponseTimestamp = possibleSampleGroup.lastDate;
			
			if([timestamp compare:lastResponseTimestamp] == NSOrderedDescending)
			{
				_insertionGroup = possibleSampleGroup;
				break;
			}
			
			insertionGroupIndex += 1;
		}
		
		if(_insertionGroup == nil)
		{
			_insertionGroup = [_DTXSampleGroup new];
			[_mergedSamples addObject:_insertionGroup];
		}
		
		NSDate* endTimestamp = [self endTimestampForSample:currentSample];
		
		NSUInteger insertionIndex = _insertionGroup.samples.count;
		[_insertionGroup.samples addObject:currentSample];
		_insertionGroup.lastDate = endTimestamp;
		
		NSIndexPath* indexPath = [NSIndexPath indexPathForItem:insertionIndex inSection:insertionGroupIndex];
		[_sampleIndices addObject:indexPath];
		_sampleMapping[currentSample.sampleIdentifier] = indexPath;
		_indexPathIndexMapping[indexPath] = @(_sampleIndices.count - 1);
	}

	DTXEndTimeMeasurment("prepare samples");
	
#if 0
	NSMutableArray* lines = [NSMutableArray new];
	
	[_sampleIndices enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSIndexPath* indexPath = obj;
		
		DTXSample* sample = self._mergedSamples[indexPath.section].samples[indexPath.item];
		
		NSTimeInterval timestamp = [sample.timestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
		NSTimeInterval responseTimestamp = [[self endTimestampForSample:sample] timeIntervalSinceReferenceDate]  - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
		
		NSMutableDictionary* line = [NSMutableDictionary new];
		line[@"start"] = @(timestamp);
		line[@"end"] = @(responseTimestamp);
		line[@"height"] = @(obj.section);
		
		CPTLineStyle* lineStyle = [self barLineStyleForRangePlot:self.plots.firstObject recordIndex:idx];
		
		line[@"color"] = lineStyle.lineColor.nsColor;
		
		[lines addObject:line];
	}];
	
	NSMutableDictionary* info = [NSMutableDictionary new];
	info[@"lines"] = lines;
	info[@"totalLength"] = @([self.document.lastRecording.defactoEndTimestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate]);
	info[@"totalHeightLines"] = @(_mergedSamples.count);
	
	[NSKeyedArchiver archiveRootObject:info toFile:@"/Users/lnatan/Desktop/lines.plist"];
#endif
	
//	os_signpost_interval_end(log, signpost_id, "_prepareMergedSamples");
}

- (BOOL)wantsGestureRecognizerForPlots
{
	return YES;
}

- (void)mouseMoved:(NSEvent *)event
{
	
}

- (CPTPlotRange*)plotRangeForSample:(DTXSample*) sample
{
	NSTimeInterval timestamp =  sample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	NSTimeInterval responseTimestamp = [self endTimestampForSample:sample].timeIntervalSinceReferenceDate  - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	return [CPTPlotRange plotRangeWithLocation:@(timestamp) length:@(responseTimestamp - timestamp)];
}

- (void)highlightSample:(DTXSample*)sample
{
	[super highlightSample:sample];
	
	if([sample isKindOfClass:DTXSampleContainerProxy.class])
	{
		return;
	}
	
	NSIndexPath* ip = _sampleMapping[sample.sampleIdentifier];
	NSUInteger indexOfIndexPath = [_indexPathIndexMapping[ip] unsignedIntegerValue];
	
	NSUInteger prevSelectedIndex = _selectedIndex;
	_selectedIndex = indexOfIndexPath;
	
	if(prevSelectedIndex != NSNotFound)
	{
		[_plotView reloadRangeAtIndex:prevSelectedIndex];
	}
	
	if(_selectedIndex != NSNotFound)
	{
		[_plotView reloadRangeAtIndex:_selectedIndex];
	}
}

- (void)_removeHighlightNotifyingDelegate:(BOOL)notify
{
	if(_selectedIndex != NSNotFound)
	{
		NSUInteger prevSelectedIndex = _selectedIndex;
		_selectedIndex = NSNotFound;
		
		[_plotView reloadRangeAtIndex:prevSelectedIndex];
	}
	
	[super _removeHighlightNotifyingDelegate:notify];
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
	
	if(_filteredDataProvider == nil)
	{
		[self _resetAfterFilter];
	}
}

- (void)_resetAfterFilter
{
	[self removeHighlight];
	
	[_plotView reloadData];
}

#pragma mark DTXFilteredDataProviderDelegate

- (void)filteredDataProviderDidFilter:(DTXFilteredDataProvider*)fdp
{
	[self _resetAfterFilter];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self _prepareMergedSamples];
	[_plotView reloadData];
}

#pragma mark Internal Plots

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if(self.isForTouchBar)
	{
		return;
	}
	
	BOOL wantsTitles = [NSUserDefaults.standardUserDefaults boolForKey:@"DTXPlotSettingsDisplayLabels"];
	_plotView.lineWidth = wantsTitles ? 3.0 : DTXRangePlotViewDefaultLineWidth;
	_plotView.drawTitles = wantsTitles;
}

- (NSArray<DTXPlotView *> *)plotViews
{
	if(_plotView == nil)
	{
		_plotView = [DTXRangePlotView new];
		if(self.isForTouchBar)
		{
			_plotView.lineSpacing = 0.0;
		}
		else
		{
			_plotView.minimumHeight = 80;
		}
		
		_plotView.translatesAutoresizingMaskIntoConstraints = NO;
		_plotView.dataSource = self;
		
		[NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"DTXPlotSettingsDisplayLabels" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
	}
	
	return @[_plotView];
}

#pragma mark DTXRangePlotViewDataSource

- (NSUInteger)numberOfSamplesInPlotView:(DTXPlotView*)plotView
{
	return _sampleIndices.count;
}

- (DTXRangePlotViewRange *)plotView:(DTXRangePlotView *)plotView rangeAtIndex:(NSUInteger)idx
{
	DTXRangePlotViewRange* rv = [DTXRangePlotViewRange new];
	
	NSIndexPath* indexPath = _sampleIndices[idx];
	
	DTXSample* sample = self._mergedSamples[indexPath.section].samples[indexPath.item];
	
	rv.start = [sample.timestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.end = [[self endTimestampForSample:sample] timeIntervalSinceReferenceDate]  - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.height = indexPath.section;
	rv.title = [self titleForSample:sample];
	
	rv.color = [self colorForSample:sample];
	
	if(_selectedIndex == idx)
	{
		rv.color = [rv.color interpolateToValue:NSColor.blackColor progress:0.35];
		rv.titleColor = NSColor.whiteColor;
	}
	else
	{
		if(rv.color.isDarkColor)
		{
			rv.titleColor = [rv.color lighterColorWithModifier:0.85];
		}
		else
		{
			rv.titleColor = [rv.color darkerColorWithModifier:0.85];
		}
	}

	if(_filteredDataProvider && [_filteredDataProvider.filteredObjectIDs containsObject:sample.objectID] == NO)
	{
		rv.color = [rv.color colorWithAlphaComponent:0.1];
		rv.titleColor = [rv.titleColor colorWithAlphaComponent:0.1];
	}
	
	return rv;
}

#pragma mark DTXRangePlotViewDelegate

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
		NSIndexPath* indexPath = _sampleIndices[idx];
		DTXSample* sample = self._mergedSamples[indexPath.section].samples[indexPath.item];
		
		if(_filteredDataProvider && [_filteredDataProvider.filteredObjectIDs containsObject:sample.objectID] == NO)
		{
			return;
		}
		
		[self highlightSample:sample];
		[self.sampleClickDelegate plotController:self didClickOnSample:sample];
	}
}

@end
