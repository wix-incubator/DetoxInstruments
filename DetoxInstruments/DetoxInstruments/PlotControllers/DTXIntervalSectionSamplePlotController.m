//
//  DTXIntervalSectionSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 2/6/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXIntervalSectionSamplePlotController.h"
#import "NSColor+UIAdditions.h"
#import "NSAppearance+UIAdditions.h"
#import <LNInterpolation/Color+Interpolation.h>
#import "DTXRecording+UIExtensions.h"

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

@interface DTXIntervalSectionSamplePlotController () <DTXRangePlotViewDataSource> @end

@implementation DTXIntervalSectionSamplePlotController
{
	NSFetchedResultsController* _frc;
	
	NSMutableArray<_DTXSampleGroup*>* _mergedSamples;
	NSMutableArray<NSIndexPath*>* _sampleIndices;
	NSMapTable<NSString*, NSIndexPath*>* _sampleMapping;
	NSMapTable<NSIndexPath*, NSNumber*>* _indexPathIndexMapping;
	NSUInteger _selectedIndex;
}

- (instancetype)initWithIntervalSamplePlotController:(DTXIntervalSamplePlotController*)intervalSamplePlotController fetchedResultsController:(NSFetchedResultsController*)frc isForTouchBar:(BOOL)isForTouchBar;
{
	self = [self init];
	
	if(self)
	{
		_isForTouchBar = isForTouchBar;
		_selectedIndex = NSNotFound;
		
		_frc = frc;
		_intervalSamplePlotController = intervalSamplePlotController;
		
		_plotView = [DTXRangePlotView new];
		if(self.isForTouchBar)
		{
			_plotView.lineSpacing = 0.0;
		}
//		else
//		{
//			_plotView.minimumHeight = 80;
//		}
		
		_plotView.translatesAutoresizingMaskIntoConstraints = NO;
		_plotView.dataSource = self;
		
		[NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:@"DTXPlotSettingsDisplayLabels" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
	}
	
	return self;
}

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

- (void)dealloc
{
	[NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"DTXPlotSettingsDisplayLabels"];
}

- (void)setFilteredDataProvider:(DTXFilteredDataProvider *)filteredDataProvider
{
	_filteredDataProvider = filteredDataProvider;
	
	if(_filteredDataProvider == nil)
	{
		[self resetAfterFilter];
	}
}

- (void)resetAfterFilter;
{
	[_plotView reloadData];
}

- (NSMutableArray<_DTXSampleGroup*>*)_mergedSamples
{
	return _mergedSamples;
}

- (void)reloadData
{
	_mergedSamples = [NSMutableArray new];
	_sampleIndices = [NSMutableArray new];
	_sampleMapping = [NSMapTable strongToStrongObjectsMapTable];
	_indexPathIndexMapping = [NSMapTable strongToStrongObjectsMapTable];
	
	if(_frc.sections[_section].numberOfObjects == 0)
	{
		return;
	}
	
	for(DTXSample* currentSample in _frc.sections[_section].objects)
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
		
		NSDate* endTimestamp = [self.intervalSamplePlotController endTimestampForSample:currentSample];
		
		NSUInteger insertionIndex = _insertionGroup.samples.count;
		[_insertionGroup.samples addObject:currentSample];
		_insertionGroup.lastDate = endTimestamp;
		
		NSIndexPath* indexPath = [NSIndexPath indexPathForItem:insertionIndex inSection:insertionGroupIndex];
		[_sampleIndices addObject:indexPath];
		_sampleMapping[currentSample.sampleIdentifier] = indexPath;
		_indexPathIndexMapping[indexPath] = @(_sampleIndices.count - 1);
	}
	
	[_plotView reloadData];
}

- (void)highlightSample:(DTXSample*)sample
{
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

- (void)removeHighlight
{
	if(_selectedIndex == NSNotFound)
	{
		return;
	}
	
	NSUInteger prevSelectedIndex = _selectedIndex;
	_selectedIndex = NSNotFound;
	
	[_plotView reloadRangeAtIndex:prevSelectedIndex];
}

- (id)sampleAtRangeIndex:(NSUInteger)idx
{
	NSIndexPath* indexPath = _sampleIndices[idx];
	return self._mergedSamples[indexPath.section].samples[indexPath.item];
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
	
	rv.start = [sample.timestamp timeIntervalSinceReferenceDate] - [self.intervalSamplePlotController.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.end = [[self.intervalSamplePlotController endTimestampForSample:sample] timeIntervalSinceReferenceDate]  - [self.intervalSamplePlotController.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.height = indexPath.section;
	rv.title = [self.intervalSamplePlotController titleForSample:sample];
	
	rv.color = [self.intervalSamplePlotController colorForSample:sample];
	
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

@end
