//
//  DTXIntervalSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/20/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXIntervalSamplePlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXGraphHostingView.h"
#import "DTXCPTRangePlot.h"
#import "DTXLineLayer.h"
#import "DTXRecording+UIExtensions.h"
#import "NSFormatter+PlotFormatters.h"
#import "NSColor+UIAdditions.h"
#import "NSAppearance+UIAdditions.h"
#import <LNInterpolation/Color+Interpolation.h>
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

@interface DTXIntervalSamplePlotController () <CPTRangePlotDataSource, CPTRangePlotDelegate, NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController<DTXSample*>* _frc;
	
	CPTRangePlot* _plot;
	
	NSMutableArray<_DTXSampleGroup*>* _mergedSamples;
	NSMutableArray<NSIndexPath*>* _sampleIndices;
	NSMapTable<NSString*, NSIndexPath*>* _sampleMapping;
	NSMapTable<NSIndexPath*, NSNumber*>* _indexPathIndexMapping;
	NSUInteger _selectedIndex;
	
	CPTPlotSpaceAnnotation* _shadowHighlightAnnotation;
	DTXLineLayer* _shadowLineLayer;
	NSTimeInterval _shadowHighlightedSampleTime;
	
	CPTPlotSpaceAnnotation* _secondShadowHighlightAnnotation;
	DTXLineLayer* _secondShadowLineLayer;
	
	CPTPlotRange* _highlightedRange;
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

- (void)setupPlotsForGraph
{
	[super setupPlotsForGraph];
	
	self.hostingView.flipped = YES;
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
}

- (void)updateLayerHandler
{
	[self _updateShadowLineColor];
}

- (void)_updateShadowLineColor
{
	if(self.wrapperView.effectiveAppearance.isDarkAppearance)
	{
		_secondShadowLineLayer.lineColors = _shadowLineLayer.lineColors = @[NSColor.whiteColor];
	}
	else
	{
		_secondShadowLineLayer.lineColors = _shadowLineLayer.lineColors = self.plotColors;
	}
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
	
//	os_signpost_interval_end(log, signpost_id, "_prepareMergedSamples");
}

- (BOOL)wantsGestureRecognizerForPlots
{
	return NO;
}

- (NSArray<CPTPlot *> *)plots
{
	if(_plot == nil)
	{
		// Create a plot that uses the data source method
		_plot = [[DTXCPTRangePlot alloc] init];
		_plot.identifier = @"Date Plot";
		
		// Add line style
		CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
		lineStyle.lineWidth = self.isForTouchBar ? 1.5 : 5.0;
		lineStyle.lineCap = kCGLineCapButt;//self.isForTouchBar ? kCGLineCapButt : kCGLineCapRound;
		_plot.barLineStyle = lineStyle;
		
		// Bar properties
		_plot.barWidth = 0.0;
		_plot.gapWidth = 0.0;
		_plot.gapHeight = 0.0;
		
		_plot.dataSource = self;
//		_plot.delegate = self;
	}
	
	return @[_plot];
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

- (void)mouseMoved:(NSEvent *)event
{
	
}

- (void)highlightSample:(DTXSample*)sample
{
	[self removeHighlight];
	
	__block NSUInteger section = NSNotFound;
	__block NSUInteger item = NSNotFound;
	
	NSIndexPath* ip = _sampleMapping[sample.sampleIdentifier];
	NSUInteger indexOfIndexPath = [_indexPathIndexMapping[ip] unsignedIntegerValue];
	
	NSUInteger prevSelectedIndex = _selectedIndex;
	_selectedIndex = indexOfIndexPath;
	
	if(_selectedIndex != NSNotFound)
	{
		[_plot reloadDataInIndexRange:NSMakeRange(_selectedIndex, 1)];
		if(prevSelectedIndex != NSNotFound)
		{
			[_plot reloadDataInIndexRange:NSMakeRange(prevSelectedIndex, 1)];
		}
	}
	else
	{
		[_plot reloadData];
	}
	
	NSTimeInterval sampleTime = sample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	
	NSTimeInterval timestamp =  sample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	NSTimeInterval responseTimestamp = [self endTimestampForSample:sample].timeIntervalSinceReferenceDate  - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	CPTPlotRange* range = [CPTPlotRange plotRangeWithLocation:@(timestamp) length:@(responseTimestamp - timestamp)];
	[self.delegate plotController:self didHighlightRange:range];
	
//	[self.delegate plotController:self didHighlightAtSampleTime:sampleTime];
	
	_shadowHighlightedSampleTime = sampleTime;
	
	if(self.graph == nil)
	{
		return;
	}
	
//	_shadowHighlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
//	_shadowLineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight + self.rangeInsets.bottom + self.rangeInsets.top)];
//	[self _updateShadowLineColor];
//	_shadowHighlightAnnotation.contentLayer = _shadowLineLayer;
//	_shadowHighlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
//	_shadowHighlightAnnotation.anchorPlotPoint = @[@(sampleTime), @(- self.rangeInsets.top)];
//
//	[self.graph addAnnotation:_shadowHighlightAnnotation];
	
	[self _highlightRange:range nofityDelegate:NO removePreviousHighlight:NO];
}

- (void)shadowHighlightAtSampleTime:(NSTimeInterval)sampleTime
{
	[self removeHighlight];
	
	_shadowHighlightedSampleTime = sampleTime;
	
	if(self.graph == nil)
	{
		return;
	}
	
	_shadowHighlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
	_shadowLineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight + self.rangeInsets.bottom + self.rangeInsets.top)];
	[self _updateShadowLineColor];
	_shadowHighlightAnnotation.contentLayer = _shadowLineLayer;
	_shadowHighlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
	_shadowHighlightAnnotation.anchorPlotPoint = @[@(sampleTime), @(- self.rangeInsets.top)];
	
	[self.graph addAnnotation:_shadowHighlightAnnotation];
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
	
	_highlightedRange = range;
	
	if(self.graph)
	{
		_shadowHighlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
		_shadowLineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight + self.rangeInsets.bottom + self.rangeInsets.top)];
		if(self.isForTouchBar == NO)
		{
			_shadowLineLayer.opacity = 0.3;
		}
		_shadowHighlightAnnotation.contentLayer = _shadowLineLayer;
		_shadowHighlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
		_shadowHighlightAnnotation.anchorPlotPoint = @[range.location, @(- self.rangeInsets.top)];
		
		_secondShadowHighlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
		_secondShadowLineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight + self.rangeInsets.bottom + self.rangeInsets.top)];
		if(self.isForTouchBar == NO)
		{
			_secondShadowLineLayer.opacity = 0.3;
		}
		_secondShadowHighlightAnnotation.contentLayer = _secondShadowLineLayer;
		_secondShadowHighlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
		_secondShadowHighlightAnnotation.anchorPlotPoint = @[@(range.locationDouble + range.lengthDouble), @(- self.rangeInsets.top)];
		
		[self _updateShadowLineColor];
		[self.graph addAnnotation:_shadowHighlightAnnotation];
		[self.graph addAnnotation:_secondShadowHighlightAnnotation];
	}
	
	if(notifyDelegate)
	{
		[self.delegate plotController:self didHighlightRange:range];
	}
}


- (void)removeHighlight
{
	if(_shadowHighlightAnnotation && _shadowHighlightAnnotation.annotationHostLayer != nil)
	{
		[self.graph removeAnnotation:_shadowHighlightAnnotation];
	}
	
	_shadowLineLayer = nil;
	_shadowHighlightAnnotation = nil;
	
	if(_secondShadowHighlightAnnotation && _secondShadowHighlightAnnotation.annotationHostLayer != nil)
	{
		[self.graph removeAnnotation:_secondShadowHighlightAnnotation];
	}
	
	_secondShadowLineLayer = nil;
	_secondShadowHighlightAnnotation = nil;
	
	_shadowHighlightedSampleTime = 0.0;
	
	if(_selectedIndex != NSNotFound)
	{
		NSUInteger prevSelectedIndex = _selectedIndex;
		_selectedIndex = NSNotFound;
		
		[_plot reloadDataInIndexRange:NSMakeRange(prevSelectedIndex, 1)];
		
//		[self.graph.allPlots.firstObject reloadData];
	}

	_highlightedRange = nil;
}

- (void)reloadHighlight
{
	if(_shadowHighlightedSampleTime != 0.0)
	{
		[self shadowHighlightAtSampleTime:_shadowHighlightedSampleTime];
	}
	else if(_highlightedRange)
	{
		[self highlightRange:_highlightedRange];
	}
}

- (CGFloat)requiredHeight
{
	NSEdgeInsets rangeInsets = self.rangeInsets;
	//The higher the number, the more spaced vertically the requests are.
	CGFloat f = self._mergedSamples.count * 9 + rangeInsets.top + rangeInsets.bottom;
	
	return MAX(f, super.requiredHeight);
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
		return NSEdgeInsetsMake(1, 0, 1, 0);
	}
	
	return NSEdgeInsetsMake(3, 0, 3, 0);
}

-(NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *)plot
{
	return _sampleIndices.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSIndexPath* indexPath = _sampleIndices[index];
	
	DTXSample* sample = self._mergedSamples[indexPath.section].samples[indexPath.item];
	
	NSTimeInterval timestamp = [sample.timestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval responseTimestamp = [[self endTimestampForSample:sample] timeIntervalSinceReferenceDate]  - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval range = responseTimestamp - timestamp;
	NSTimeInterval avg = (timestamp + responseTimestamp) / 2;
	
	CGFloat ratio = 1.0;
//	if(self.isForTouchBar)
//	{
//		ratio = self.wrapperView.bounds.size.height / self.requiredHeight;
//	}
	
	switch (fieldEnum)
	{
		case CPTRangePlotFieldX:
			return @(avg);
		case CPTRangePlotFieldY:
			return @(ratio * (indexPath.section * 3));
		case CPTRangePlotFieldLeft:
		case CPTRangePlotFieldRight:
			return @(range / 2.0);
		case CPTRangePlotFieldHigh:
			return @0;//@3.25;
		case CPTRangePlotFieldLow:
			return @0;// @-3.25;
		default:
			return @0;
	}
}

-(nullable CPTLineStyle *)barLineStyleForRangePlot:(nonnull CPTRangePlot *)plot recordIndex:(NSUInteger)idx
{
	CPTMutableLineStyle* lineStyle = [plot.barLineStyle mutableCopy];
	
	NSIndexPath* indexPath = _sampleIndices[idx];
	DTXSample* sample = _mergedSamples[indexPath.section].samples[indexPath.item];
	
	NSColor* lineColor = [self colorForSample:sample];
	
	if(_selectedIndex == idx)
	{
		lineStyle.lineWidth = 6.5;
	}
	
	if(_selectedIndex == idx)
	{
		lineColor = [lineColor interpolateToValue:NSColor.blackColor progress:0.35];
	}

	lineStyle.lineColor = [CPTColor colorWithCGColor:lineColor.CGColor];
	
	return lineStyle;
}

- (NSDate*)endTimestampForSample:(DTXSample*)sample
{
	return nil;
}

- (NSColor*)colorForSample:(DTXSample*)sample
{
	return nil;
}

- (NSArray<NSSortDescriptor *> *)sortDescriptors
{
	return nil;
}

#pragma mark CPTRangePlotDelegate

-(void)rangePlot:(nonnull CPTRangePlot *)plot rangeWasSelectedAtRecordIndex:(NSUInteger)idx withEvent:(nonnull CPTNativeEvent *)event
{
	if(event.type != NSEventTypeLeftMouseUp)
	{
		return;
	}
	
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
	
	[self highlightSample:sample];
	[self.sampleClickDelegate plotController:self didClickOnSample:sample];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	CGFloat oldHeight = self.requiredHeight;

	[self _prepareMergedSamples];
	[_plot reloadData];
	CPTPlotRange* range = [_plot plotRangeForCoordinate:CPTCoordinateY];
	range = [self finessedPlotYRangeForPlotYRange:range];

	CPTXYPlotSpace* plotSpace = (id)self.graph.defaultPlotSpace;
	[self setValue:range forKey:@"_globalYRange"];
	plotSpace.globalYRange = plotSpace.yRange = range;

	CGFloat newHeight = self.requiredHeight;

	if(newHeight != oldHeight)
	{
		//Because of macOS bugs, delay the height change notification to next runloop.
		dispatch_async(dispatch_get_main_queue(), ^{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate requiredHeightChangedForPlotController:self];
			});
		});
	}
}

@end
