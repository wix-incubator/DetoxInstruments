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

@interface DTXIntervalSamplePlotController () <CPTRangePlotDataSource, NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController<DTXSample*>* _frc;
	
	CPTRangePlot* _plot;
	
	NSMutableArray<NSMutableArray<DTXSample*>*>* _mergedSamples;
	NSMutableArray<NSIndexPath*>* _sampleIndices;
	NSUInteger _selectedIndex;
	
	CPTPlotSpaceAnnotation* _shadowHighlightAnnotation;
	DTXLineLayer* _shadowLineLayer;
	NSTimeInterval _shadowHighlightedSampleTime;
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
	NSFetchRequest* fr = [self.class.classForIntervalSamples fetchRequest];
	fr.sortDescriptors = self.sortDescriptors ?: @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.recording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	_frc.delegate = self;
	[_frc performFetch:NULL];
}

- (void)updateLayerHandler
{
	[self _updateShadowLineColor];
}

- (void)_updateShadowLineColor
{
	if(self.wrapperView.effectiveAppearance.isDarkAppearance)
	{
		_shadowLineLayer.lineColor = NSColor.whiteColor;
	}
	else
	{
		_shadowLineLayer.lineColor = [([self.plotColors.lastObject deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15]) colorWithAlphaComponent:0.5];
	}
}

- (NSMutableArray<NSMutableArray<DTXSample*>*>*)_mergedSamples
{
	if(_frc == nil)
	{
		[self prepareSamples];
	}
	
	if(_mergedSamples == nil)
	{
		[self _prepareMergedSamples];
	}
	
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
	
	if(_frc.fetchedObjects.count == 0)
	{
		return;
	}
	
	[_frc.fetchedObjects enumerateObjectsUsingBlock:^(DTXSample* _Nonnull currentSample, NSUInteger idx, BOOL * _Nonnull stop) {
		NSDate* timestamp = currentSample.timestamp;
		
		__block NSMutableArray* _insertionGroup = nil;
		
		[_mergedSamples enumerateObjectsUsingBlock:^(NSMutableArray<DTXSample *> * _Nonnull possibleSampleGroup, NSUInteger idx, BOOL * _Nonnull stop) {
			NSDate* lastResponseTimestamp = [self endTimestampForSampleForSorting:possibleSampleGroup.lastObject];
			
			if([timestamp compare:lastResponseTimestamp] == NSOrderedDescending)
			{
				_insertionGroup = possibleSampleGroup;
				*stop = YES;
			}
		}];
		
		if(_insertionGroup == nil)
		{
			_insertionGroup = [NSMutableArray new];
			[_mergedSamples addObject:_insertionGroup];
		}
		
		[_insertionGroup addObject:currentSample];
		
		NSIndexPath* indexPath = [NSIndexPath indexPathForItem:[_insertionGroup indexOfObject:currentSample] inSection:[_mergedSamples indexOfObject:_insertionGroup]];
		[_sampleIndices addObject:indexPath];
	}];
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
		lineStyle.lineWidth = 5.0;
		lineStyle.lineCap = kCGLineCapRound;
		_plot.barLineStyle = lineStyle;
		
		// Bar properties
		_plot.barWidth = 0.0;
		_plot.gapWidth = 0.0;
		_plot.gapHeight = 0.0;
		
		_plot.dataSource = self;
	}
	
	return @[_plot];
}

- (void)mouseMoved:(NSEvent *)event
{
	
}

- (void)highlightSample:(DTXSample*)sample
{
	[self removeHighlight];
	
	__block NSUInteger section = NSNotFound;
	__block NSUInteger item = NSNotFound;
	
	[self._mergedSamples enumerateObjectsUsingBlock:^(NSMutableArray<DTXSample *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj enumerateObjectsUsingBlock:^(DTXSample * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if(obj != sample)
			{
				return;
			}
			
			item = idx;
			*stop = YES;
		}];
		
		if(item == NSNotFound)
		{
			return;
		}
		
		section = idx;
		*stop = YES;
	}];
	
	NSIndexPath* ip = [NSIndexPath indexPathForItem:item inSection:section];
	NSUInteger indexOfIndexPath = [_sampleIndices indexOfObject:ip];
	
	NSUInteger prevSelectedIndex = _selectedIndex;
	_selectedIndex = indexOfIndexPath;
	
	if(indexOfIndexPath != NSNotFound)
	{
		[_plot reloadDataInIndexRange:NSMakeRange(indexOfIndexPath, 1)];
		if(prevSelectedIndex != NSNotFound)
		{
			[_plot reloadDataInIndexRange:NSMakeRange(prevSelectedIndex, 1)];
		}
	}
	else
	{
		[_plot reloadData];
	}
	
	NSTimeInterval sampleTime = sample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
	
	[self.delegate plotController:self didHighlightAtSampleTime:sampleTime];
	
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

- (void)highlightRange:(CPTPlotRange *)range
{
	[self removeHighlight];
	
	[self.delegate plotController:self didHighlightRange:range];
}

- (void)shadowHighlightRange:(CPTPlotRange*)range
{
	[self removeHighlight];
}

- (void)removeHighlight
{
	if(_shadowHighlightAnnotation && _shadowHighlightAnnotation.annotationHostLayer != nil)
	{
		[self.graph removeAnnotation:_shadowHighlightAnnotation];
	}
	
	_shadowLineLayer = nil;
	_shadowHighlightAnnotation = nil;
	_shadowHighlightedSampleTime = 0.0;
	
	if(_selectedIndex != NSNotFound)
	{
		NSUInteger prevSelectedIndex = _selectedIndex;
		_selectedIndex = NSNotFound;
		
		[_plot reloadDataInIndexRange:NSMakeRange(prevSelectedIndex, 1)];
		
//		[self.graph.allPlots.firstObject reloadData];
	}
}

- (void)reloadHighlight
{
	if(_shadowHighlightedSampleTime != 0.0)
	{
		[self shadowHighlightAtSampleTime:_shadowHighlightedSampleTime];
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
	return NSEdgeInsetsMake(3, 0, 3, 0);
}

-(NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *)plot
{
	return _sampleIndices.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSIndexPath* indexPath = _sampleIndices[index];
	
	DTXSample* sample = self._mergedSamples[indexPath.section][indexPath.item];
	
	NSTimeInterval timestamp = [sample.timestamp timeIntervalSinceReferenceDate] - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval responseTimestamp = [[self endTimestampForSample:sample] timeIntervalSinceReferenceDate]  - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval range = responseTimestamp - timestamp;
	NSTimeInterval avg = (timestamp + responseTimestamp) / 2;
	
	switch (fieldEnum)
	{
		case CPTRangePlotFieldX:
			return @(avg);
		case CPTRangePlotFieldY:
			return @(indexPath.section * 3);
		case CPTRangePlotFieldLeft:
		case CPTRangePlotFieldRight:
			return @(range / 2.0);
		default:
			return @0;
	}
}

-(nullable CPTLineStyle *)barLineStyleForRangePlot:(nonnull CPTRangePlot *)plot recordIndex:(NSUInteger)idx
{
	CPTMutableLineStyle* lineStyle = [plot.barLineStyle mutableCopy];
	
	NSIndexPath* indexPath = _sampleIndices[idx];
	DTXSample* sample = _mergedSamples[indexPath.section][indexPath.item];
	
	NSColor* lineColor = [self colorForSample:sample];
	
	if(_selectedIndex == idx)
	{
		lineStyle.lineWidth = 6.5;
	}
	
	if(_selectedIndex == idx)
	{
		lineColor = [lineColor blendedColorWithFraction:0.35 ofColor:NSColor.blackColor];
	}
	
	lineStyle.lineColor = [CPTColor colorWithCGColor:lineColor.CGColor];
	
	return lineStyle;
}

- (NSDate*)endTimestampForSampleForSorting:(DTXSample*)sample
{
	return [self endTimestampForSample:sample];
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

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	CGFloat oldHeight = self.requiredHeight;
	
	[self _prepareMergedSamples];
	[_plot reloadData];
	CPTPlotRange* range = [_plot plotRangeForCoordinate:CPTCoordinateY];
	range = [self finesedPlotRangeForPlotRange:range];
	
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
