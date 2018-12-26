//
//  DTXIntervalSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/20/18.
//  Copyright © 2018 Wix. All rights reserved.
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

@interface DTXIntervalSamplePlotController () <DTXRangePlotViewDelegate, DTXRangePlotViewDataSource, CPTRangePlotDataSource, CPTRangePlotDelegate, NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController<DTXSample*>* _frc;
	
	DTXRangePlotView* _plotView;
	
	NSMutableArray<_DTXSampleGroup*>* _mergedSamples;
	NSMutableArray<NSIndexPath*>* _sampleIndices;
	NSMapTable<NSString*, NSIndexPath*>* _sampleMapping;
	NSMapTable<NSIndexPath*, NSNumber*>* _indexPathIndexMapping;
	NSUInteger _selectedIndex;
}
@end

@implementation DTXIntervalSamplePlotController

+ (Class)classForIntervalSamples
{
	return nil;
}

- (instancetype)initWithDocument:(DTXRecordingDocument *)document
{
	self = [super initWithDocument:document];
	
	if(self)
	{
		_selectedIndex = NSNotFound;
	}
	
	return self;
}

- (BOOL)usesInternalPlots
{
	return YES;
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

- (void)_updateAnnotationColors:(NSArray<DTXPlotViewAnnotation*>*)annotations
{
	[annotations enumerateObjectsUsingBlock:^(DTXPlotViewAnnotation * _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
		if(self.wrapperView.effectiveAppearance.isDarkAppearance)
		{
			annotation.color = NSColor.whiteColor;
		}
		else
		{
			annotation.color = self.plotColors.firstObject;
		}
	}];
}

- (void)updateLayerHandler
{
	[self _updateAnnotationColors:_plotView.annotations];
	_plotView.annotations = _plotView.annotations;
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
	CFTimeInterval startTime = CACurrentMediaTime();

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

	CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
	NSLog(@"%@ took %@ seconds to prepare samples", self.class, @(elapsedTime));
	
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

- (void)highlightSample:(DTXSample*)sample
{
	[self removeHighlight];
	
	NSIndexPath* ip = _sampleMapping[sample.sampleIdentifier];
	NSUInteger indexOfIndexPath = [_indexPathIndexMapping[ip] unsignedIntegerValue];
	
	NSUInteger prevSelectedIndex = _selectedIndex;
	_selectedIndex = indexOfIndexPath;
	
	if(_selectedIndex != NSNotFound)
	{
		[_plotView reloadRangeAtIndex:_selectedIndex];
		if(prevSelectedIndex != NSNotFound)
		{
			[_plotView reloadRangeAtIndex:prevSelectedIndex];
		}
	}
	else
	{
		[_plotView reloadData];
	}
	
	NSTimeInterval timestamp =  sample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	NSTimeInterval responseTimestamp = [self endTimestampForSample:sample].timeIntervalSinceReferenceDate  - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	CPTPlotRange* range = [CPTPlotRange plotRangeWithLocation:@(timestamp) length:@(responseTimestamp - timestamp)];
	[self.delegate plotController:self didHighlightRange:range];
	
	[self _highlightRange:range nofityDelegate:NO removePreviousHighlight:NO];
}

- (void)shadowHighlightAtSampleTime:(NSTimeInterval)sampleTime
{
	[self removeHighlight];
	
	DTXPlotViewAnnotation* annotation = [DTXPlotViewAnnotation new];
	annotation.position = sampleTime;
	
	NSArray* annotations = @[annotation];
	[self _updateAnnotationColors:annotations];
	
	_plotView.annotations = annotations;
}

- (void)highlightRange:(CPTPlotRange*)range
{
	[self _highlightRange:range nofityDelegate:YES removePreviousHighlight:YES];
}

- (void)shadowHighlightRange:(CPTPlotRange*)range
{
	[self _highlightRange:range nofityDelegate:NO removePreviousHighlight:YES];
}

- (void)_highlightRange:(CPTPlotRange*)range nofityDelegate:(BOOL)notifyDelegate removePreviousHighlight:(BOOL)removePreviousHighlight
{
	if(removePreviousHighlight)
	{
		[self removeHighlight];
	}
	
	DTXPlotViewAnnotation* annotation1 = [DTXPlotViewAnnotation new];
	annotation1.position = range.locationDouble;
	annotation1.color = NSColor.textColor;
	if(self.isForTouchBar == NO)
	{
		annotation1.opacity = 0.3;
	}
	
	NSMutableArray* annotations = [NSMutableArray arrayWithObject:annotation1];
	
	if(range.length)
	{
		DTXPlotViewAnnotation* annotation2 = [DTXPlotViewAnnotation new];
		annotation2.position = range.locationDouble + range.lengthDouble;
		annotation2.color = NSColor.textColor;
		if(self.isForTouchBar == NO)
		{
			annotation2.opacity = 0.3;
		}
		
		[annotations addObject:annotation2];
	}
	
	[self _updateAnnotationColors:annotations];
	
	_plotView.annotations = annotations;
	
	if(notifyDelegate)
	{
		[self.delegate plotController:self didHighlightRange:range];
	}
}


- (void)removeHighlight
{
	_plotView.annotations = nil;
	
	if(_selectedIndex != NSNotFound)
	{
		NSUInteger prevSelectedIndex = _selectedIndex;
		_selectedIndex = NSNotFound;
		
		[_plotView reloadRangeAtIndex:prevSelectedIndex];
	}
}

- (void)reloadHighlight
{
}

- (BOOL)isStepped
{
	return YES;
}

- (CGFloat)yRangeMultiplier;
{
	return 1;
}

- (NSEdgeInsets)rangeInsets
{
	if(self.isForTouchBar)
	{
		return NSEdgeInsetsZero;
	}
	
	return NSEdgeInsetsMake(5, 0, 5, 0);
}

- (CPTPlotRange*)finessedPlotYRangeForPlotYRange:(CPTPlotRange*)yRange;
{
	NSEdgeInsets insets = self.rangeInsets;
	
	CPTMutablePlotRange* rv = [yRange mutableCopy];
	
	CGFloat initial = rv.location.doubleValue;
	rv.location = @(-insets.bottom);
	rv.length = @((initial + rv.length.doubleValue + insets.top + insets.bottom) * self.yRangeMultiplier);
	
	return rv;
}

- (NSDate*)endTimestampForSample:(DTXSample*)sample
{
	return nil;
}

- (NSColor*)colorForSample:(DTXSample*)sample
{
	return nil;
}

- (CGLineCap)lineCapForSample:(__kindof DTXSample*)sample
{
	return kCGLineCapButt;
}

- (NSArray<NSSortDescriptor *> *)sortDescriptors
{
	return nil;
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self _prepareMergedSamples];
	[_plotView reloadData];
}

- (void)_selectSampleAtIndex:(NSUInteger)idx
{
	if(self.canReceiveFocus == NO)
	{
		return;
	}
	
	if(self.isForTouchBar)
	{
		return;
	}
	
	NSIndexPath* indexPath = _sampleIndices[idx];
	DTXSample* sample = self._mergedSamples[indexPath.section].samples[indexPath.item];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self highlightSample:sample];
		[self.sampleClickDelegate plotController:self didClickOnSample:sample];
	});
}

#pragma mark Internal Plots

- (NSArray<DTXPlotView *> *)plotViews
{
	if(_plotView == nil)
	{
		_plotView = [DTXRangePlotView new];
		if(self.isForTouchBar)
		{
			_plotView.lineSpacing = 0.0;
		}
		_plotView.translatesAutoresizingMaskIntoConstraints = NO;
		_plotView.dataSource = self;
	}
	
	return @[_plotView];
}

#pragma mark DTXRangePlotViewDataSource

- (NSUInteger)numberOfSamplesInPlotView:(DTXPlotView*)plotView
{
	return _sampleIndices.count;
}

- (DTXRange *)plotView:(DTXRangePlotView *)plotView rangeAtIndex:(NSUInteger)idx
{
	DTXRange* rv = [DTXRange new];
	
	NSIndexPath* indexPath = _sampleIndices[idx];
	
	DTXSample* sample = self._mergedSamples[indexPath.section].samples[indexPath.item];
	
	rv.start = [sample.timestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.end = [[self endTimestampForSample:sample] timeIntervalSinceReferenceDate]  - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.height = indexPath.section;
	
	NSColor* lineColor = [self colorForSample:sample];
	
	if(_selectedIndex == idx)
	{
		lineColor = [lineColor interpolateToValue:NSColor.blackColor progress:0.35];
	}
	
	rv.color = lineColor;
	
	return rv;
}

#pragma mark DTXRangePlotViewDelegate

- (void)plotView:(DTXRangePlotView *)plotView didClickRangeAtIndex:(NSUInteger)idx
{
	[self _selectSampleAtIndex:idx];
}

@end
