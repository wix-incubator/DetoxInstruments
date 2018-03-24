//
//  DTXCompactNetworkRequestsPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCompactNetworkRequestsPlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXNetworkSample+CoreDataClass.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXGraphHostingView.h"
#import "DTXNetworkDataProvider.h"
#import "DTXCPTRangePlot.h"
#import "DTXLineLayer.h"
#import "DTXRecording+UIExtensions.h"

@interface DTXCompactNetworkRequestsPlotController () <CPTRangePlotDataSource, NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController<DTXNetworkSample*>* _frc;
	
	CPTRangePlot* _plot;
	
	NSMutableArray<NSMutableArray<DTXNetworkSample*>*>* _mergedSamples;
	NSMutableArray<NSIndexPath*>* _sampleIndices;
	NSUInteger _selectedIndex;
	
	CPTPlotSpaceAnnotation* _shadowHighlightAnnotation;
	DTXLineLayer* _shadowLineLayer;
	NSTimeInterval _shadowHighlightedSampleTime;
}
@end

@implementation DTXCompactNetworkRequestsPlotController

+ (Class)graphHostingViewClass
{
	return [DTXInvertedGraphHostingView class];
}

+ (Class)UIDataProviderClass
{
	return [DTXNetworkDataProvider class];
}

- (instancetype)initWithDocument:(DTXDocument *)document
{
	self = [super initWithDocument:document];
	
	if(self)
	{
		_selectedIndex = NSNotFound;
	}
	
	return self;
}

- (void)prepareSamples
{
	NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	_frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.recording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	_frc.delegate = self;
	[_frc performFetch:NULL];
}

- (NSMutableArray<NSMutableArray<DTXNetworkSample*>*>*)_mergedSamples
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

- (void)_prepareMergedSamples
{
	_mergedSamples = [NSMutableArray new];
	_sampleIndices = [NSMutableArray new];
	
	if(_frc.fetchedObjects.count == 0)
	{
		return;
	}
	
	[_frc.fetchedObjects enumerateObjectsUsingBlock:^(DTXNetworkSample * _Nonnull currentSample, NSUInteger idx, BOOL * _Nonnull stop) {
		NSDate* timestamp = currentSample.timestamp;
		
		__block NSMutableArray* _insertionGroup = nil;
		
		[_mergedSamples enumerateObjectsUsingBlock:^(NSMutableArray<DTXNetworkSample *> * _Nonnull possibleSampleGroup, NSUInteger idx, BOOL * _Nonnull stop) {
			NSDate* lastResponseTimestamp = possibleSampleGroup.lastObject.responseTimestamp;
			if(lastResponseTimestamp == nil)
			{
				lastResponseTimestamp = [NSDate distantFuture];
			}
			
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
	// Create a plot that uses the data source method
	_plot = [[DTXCPTRangePlot alloc] init];
	_plot.identifier = @"Date Plot";
	
	// Add line style
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth = 1.25;
	lineStyle.lineColor = [CPTColor colorWithCGColor:self.plotColors.firstObject.CGColor];
	_plot.barLineStyle = lineStyle;
	
	// Bar properties
	_plot.barWidth = 6.0;
	_plot.gapWidth = 0.0;
	_plot.gapHeight = 0.0;
	
	_plot.dataSource = self;
	
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
	
	[self._mergedSamples enumerateObjectsUsingBlock:^(NSMutableArray<DTXNetworkSample *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj enumerateObjectsUsingBlock:^(DTXNetworkSample * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
	
	if([self.delegate respondsToSelector:@selector(plotController:didHighlightAtSampleTime:)])
	{
		NSTimeInterval sampleTime = sample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.defactoStartTimestamp.timeIntervalSinceReferenceDate;
		[self.delegate plotController:self didHighlightAtSampleTime:sampleTime];
	}
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
	_shadowLineLayer.lineColor = [self.plotColors.firstObject colorWithAlphaComponent:0.25];
	_shadowHighlightAnnotation.contentLayer = _shadowLineLayer;
	_shadowHighlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
	_shadowHighlightAnnotation.anchorPlotPoint = @[@(sampleTime), @(- self.rangeInsets.top)];
	
	[self.graph addAnnotation:_shadowHighlightAnnotation];
}

- (void)highlightRange:(CPTPlotRange *)range
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
		_selectedIndex = NSNotFound;
		
		[self.graph.allPlots.firstObject reloadData];
	}
}

- (void)reloadHighlight
{
	if(_shadowHighlightedSampleTime != 0.0)
	{
		[self shadowHighlightAtSampleTime:_shadowHighlightedSampleTime];
	}
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Network Activity", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Network Activity instrument captures information about the profiled app's network activity.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"networkActivity"];
}

- (CGFloat)requiredHeight
{
	CGFloat f = self._mergedSamples.count * 2 * 4 + 6;
	
	return MAX(f, super.requiredHeight);
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"totalDataLength"];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"URL", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor colorWithRed:68.0/255.0 green:190.0/255.0 blue:30.0/255.0 alpha:1.0]];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
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
	
	DTXNetworkSample* sample = self._mergedSamples[indexPath.section][indexPath.item];
	
	NSTimeInterval timestamp = [sample.timestamp timeIntervalSinceReferenceDate] - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval responseTimestamp = [sample.responseTimestamp ?: [NSDate distantFuture] timeIntervalSinceReferenceDate]  - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
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
	DTXNetworkSample* sample = _mergedSamples[indexPath.section][indexPath.item];
	   
	if(_selectedIndex == idx)
	{
		lineStyle.lineWidth = 3;
		lineStyle.lineColor = [CPTColor colorWithCGColor:[self.plotColors.firstObject blendedColorWithFraction:0.09 ofColor:NSColor.blackColor].CGColor];
	}
	
	if(sample.responseStatusCode == 0)
	{
		lineStyle.lineColor = [CPTColor colorWithCGColor:NSColor.warningColor.CGColor];
	}
	else if(sample.responseStatusCode < 200 || sample.responseStatusCode >= 400)
	{
		lineStyle.lineColor = [CPTColor colorWithCGColor:NSColor.warning2Color.CGColor];
	}
	
	if(sample.responseError)
	{
		lineStyle.lineColor = [CPTColor colorWithCGColor:NSColor.warning3Color.CGColor];
	}
	
	return lineStyle;
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

