//
//  DTXSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSamplePlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXGraphHostingView.h"
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXLineLayer.h"
#import <LNInterpolation/LNInterpolation.h>
#import "DTXRecording+UIExtensions.h"
#import "DTXStackedPlotGroup.h"
#import "DTXCPTScatterPlot.h"
#import "DTXDetailController.h"
#import "NSAppearance+UIAdditions.h"

@interface DTXSamplePlotController () <CPTScatterPlotDelegate>

@end

@implementation DTXSamplePlotController
{
	CPTPlotRange* _globalYRange;
	CPTPlotRange* _pendingGlobalXPlotRange;
	CPTPlotRange* _pendingXPlotRange;
	
	NSStoryboard* _scene;
	
	CGRect _lastDrawBounds;
	
	CPTPlotSpaceAnnotation* _highlightAnnotation;
	DTXLineLayer* _lineLayer;
	
	CPTPlotSpaceAnnotation* _secondHighlightAnnotation;
	DTXLineLayer* _secondLineLayer;
	
	NSUInteger _highlightedSampleIndex;
	NSUInteger _highlightedNextSampleIndex;
	NSTimeInterval _highlightedSampleTime;
	CGFloat _highlightedPercent;
	
	NSMutableArray<CPTLimitBand*>* _rangeHighlightBandArray;
	CPTPlotRange* _highlightedRange;
	
	CPTPlotSpaceAnnotation* _shadowHighlightAnnotation;
	DTXLineLayer* _shadowLineLayer;
	
	CPTPlotSpaceAnnotation* _secondShadowHighlightAnnotation;
	DTXLineLayer* _secondShadowLineLayer;
	
	NSTimeInterval _shadowHighlightedSampleTime;
	
	NSArray* _plots;
	
	BOOL _atLeastOnce;
}

@synthesize delegate = _delegate;
@synthesize document = _document;
@synthesize dataProviderControllers = _dataProviderControllers;
@synthesize sampleClickDelegate = _sampleClickDelegate;
@synthesize parentPlotController = _parentPlotController;

+ (Class)graphHostingViewClass
{
	return [DTXGraphHostingView class];
}

+ (Class)UIDataProviderClass
{
	return nil;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document
{
	self = [super init];

	if(self)
	{
		_document = document;
		_scene = [NSStoryboard storyboardWithName:@"Profiler" bundle:nil];
		
		_rangeHighlightBandArray = [NSMutableArray new];
		
		//To initialize the highlighed cache ivars.
		[self _removeHighlightNotifyDelegate:NO];
		
	}
	
	return self;
}

- (NSArray<DTXDetailController *> *)dataProviderControllers
{
	DTXDetailController* detailController = [_scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
	detailController.detailDataProvider = [[self.class.UIDataProviderClass alloc] initWithDocument:_document plotController:self];
	
	return @[detailController];
}

- (void)mouseEntered:(NSEvent *)event
{
	
}

- (void)mouseExited:(NSEvent *)event
{
	[self.hostingView removeAllToolTips];
}

- (void)mouseMoved:(NSEvent *)event
{
	CGPoint pointInView = [self.hostingView convertPoint:[event locationInWindow] fromView:nil];
	
	NSMutableArray<NSDictionary<NSString*, NSString*>*>* dataPoints = [NSMutableArray new];
	
	[self.graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSUInteger numberOfRecords = [self numberOfRecordsForPlot:obj];
		NSUInteger foundPointIndex = NSNotFound;
		CGFloat foundPointDelta = 0;
		CGFloat foundPointX = 0;
		for(NSUInteger idx = 0; idx < numberOfRecords; idx++)
		{
			CGPoint pointOfPoint = [obj plotAreaPointOfVisiblePointAtIndex:idx];
			if(pointOfPoint.x <= pointInView.x)
			{
				foundPointIndex = idx;
				foundPointDelta = pointInView.x - pointOfPoint.x;
				foundPointX = pointOfPoint.x;
			}
			else
			{
				break;
			}
		}
		
		if(foundPointIndex != NSNotFound)
		{
			id y = [self numberForPlot:obj field:CPTScatterPlotFieldY recordIndex:foundPointIndex];
			if(self.isStepped == NO && foundPointIndex < numberOfRecords - 1)
			{
				CGPoint pointOfNextPoint = [obj plotAreaPointOfVisiblePointAtIndex:foundPointIndex + 1];
				id nextY = [self numberForPlot:obj field:CPTScatterPlotFieldY recordIndex:foundPointIndex + 1];
				
				y = [y interpolateToValue:nextY progress:foundPointDelta / (pointOfNextPoint.x - foundPointX)];
			}
			
			[dataPoints addObject:@{@"title":self.plotTitles[idx], @"data": [self.class.formatterForDataPresentation stringForObjectValue:[self transformedValueForFormatter:y]]}];
		}
	}];
	
	if(dataPoints.count == 0)
	{
		return;
	}
	
	[self.hostingView removeAllToolTips];
	if(dataPoints.count == 1)
	{
		[self.hostingView setToolTip:dataPoints.firstObject[@"data"]];
	}
	else
	{
		NSMutableString* tooltip = [NSMutableString new];
		[dataPoints enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[tooltip appendString:[NSString stringWithFormat:@"%@: %@\n", obj[@"title"], obj[@"data"]]];
		}];
		
		[self.hostingView setToolTip:[tooltip stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
	}
}

- (void)clickedByClickGestureRegonizer:(NSClickGestureRecognizer*)cgr
{
	if(self.canReceiveFocus == NO)
	{
		return;
	}
	
	[self.delegate plotControllerUserDidClickInPlotBounds:self];
	
	if([self.graph.allPlots.firstObject isKindOfClass:[CPTScatterPlot class]])
	{
		NSPoint pointInView = [cgr locationInView:self.hostingView];
		
		CPTNumberArray* pointInPlot = [self.graph.defaultPlotSpace plotPointForPlotAreaViewPoint:pointInView];
		
		NSUInteger numberOfRecords = [self numberOfRecordsForPlot:self.plots.firstObject];
		NSUInteger foundPointIndex = NSNotFound;
		CGFloat foundPointDelta = 0;
		for(NSUInteger idx = 0; idx < numberOfRecords; idx++)
		{
			NSNumber* xOfPointInPlot = [self numberForPlot:self.graph.allPlots.firstObject field:CPTScatterPlotFieldX recordIndex:idx];
			if(xOfPointInPlot.doubleValue <= pointInPlot.firstObject.doubleValue)
			{
				foundPointIndex = idx;
				foundPointDelta = pointInPlot.firstObject.doubleValue - xOfPointInPlot.doubleValue;
			}
			else
			{
				break;
			}
		}
		
		if(foundPointIndex == NSNotFound)
		{
			return;
		}
		
		id sample = [self samplesForPlotIndex:((NSNumber*)self.plots.firstObject.identifier).unsignedIntegerValue][foundPointIndex];
		id nextSample = foundPointIndex == numberOfRecords - 1 ? nil : [self samplesForPlotIndex:((NSNumber*)self.plots.firstObject.identifier).unsignedIntegerValue][foundPointIndex + 1];
		
		if(self.parentPlotController)
		{
			DTXSamplePlotController* spc = (id)self.parentPlotController;
			[spc _highlightSample:sample nextSample:nextSample plotSpaceOffset:foundPointDelta notifyDelegate:YES];
		}
		else
		{
			[self _highlightSample:sample nextSample:nextSample plotSpaceOffset:foundPointDelta notifyDelegate:YES];
		}
		
		[self.sampleClickDelegate plotController:(id)self.parentPlotController ?: self didClickOnSample:sample];
	}
}

- (CPTPlotRange*)finessedPlotYRangeForPlotYRange:(CPTPlotRange*)yRange;
{
	NSEdgeInsets insets = self.rangeInsets;
	
	CPTMutablePlotRange* rv = [yRange mutableCopy];
	
	CGFloat initial = rv.location.doubleValue;
	rv.location = @(-insets.bottom);
	rv.length = @((initial + rv.length.doubleValue + insets.top + insets.bottom) * self.yRangeMultiplier * self.sampleKeys.count);
	
	return rv;
}

- (void)updateLayerHandler
{
	NSArray<NSColor*>* plotColors = self.plotColors;
	
	[self.plots enumerateObjectsUsingBlock:^(__kindof CPTPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		BOOL isDark = self.wrapperView.effectiveAppearance.isDarkAppearance;
		BOOL isTouchBar = self.wrapperView.effectiveAppearance.isTouchBarAppearance;
		
		CPTMutableLineStyle *lineStyle = [((CPTScatterPlot*)obj).dataLineStyle mutableCopy];
		CGFloat maxWidth = isDark ? 1.5 : 1.0;
		lineStyle.lineWidth = isTouchBar ? 0.0 : MAX(1.0, maxWidth / self.hostingView.layer.contentsScale);
		
		NSColor* lineColor;
		
		if(isDark)
		{
			lineColor = NSColor.whiteColor;//[plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:1.0];
		}
		else
		{
			lineColor = [plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
		}
		
		lineStyle.lineColor = [CPTColor colorWithCGColor:lineColor.CGColor];
		
		((CPTScatterPlot*)obj).dataLineStyle = lineStyle;
		
		NSColor* startColor;
		NSColor* endColor;
		CPTFill* fill;
		
		if(isTouchBar)
		{
			startColor = self.plotColors[idx];
//			startColor = [startColor colorWithAlphaComponent:0.4];
			fill = [CPTFill fillWithColor:[CPTColor colorWithCGColor:startColor.CGColor]];
		}
		else if(isDark)
		{
			endColor = [self.plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.25];//[plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.1];//[plotColors[idx] colorWithAlphaComponent:0.5];
			startColor = [self.plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.25];//[plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];//[plotColors[idx] colorWithAlphaComponent:0.85];
			startColor = [startColor colorWithAlphaComponent:0.9];
			fill = [CPTFill fillWithColor:[CPTColor colorWithCGColor:startColor.CGColor]];
		}
		else
		{
			startColor = [plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.5];
			endColor = [plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.7];
			
			CPTGradient* gradient = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:startColor.CGColor] endingColor:[CPTColor colorWithCGColor:endColor.CGColor]];
			gradient.gradientType = CPTGradientTypeAxial;
			gradient.angle = 90;
			
			fill = [CPTFill fillWithGradient:gradient];
		}
		
		((CPTScatterPlot*)obj).areaFill = fill;
	}];
	
	[self _updateShadowLineColor];
	[self _updateLineColor];
	
	if(_rangeHighlightBandArray.count > 0)
	{
		[self.graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTScatterPlot * _Nonnull plot, NSUInteger idx, BOOL * _Nonnull stop) {
			CPTLimitBand* band = _rangeHighlightBandArray[idx];
			[plot removeAreaFillBand:band];
			band = [self _highlightBandForRange:_highlightedRange color:self.plotColors[idx]];
			[plot addAreaFillBand:band];
			_rangeHighlightBandArray[idx] = band;
		}];
	}
	[_lineLayer setNeedsDisplay];
	[_secondLineLayer setNeedsDisplay];
	[_shadowLineLayer setNeedsDisplay];
}

- (void)_updateShadowLineColor
{
	if(self.wrapperView.effectiveAppearance.isDarkAppearance)
	{
		_secondShadowLineLayer.lineColors = _shadowLineLayer.lineColors = @[NSColor.whiteColor];
	}
	else
	{
		NSMutableArray<NSColor*>* colors = [NSMutableArray new];
		for(NSColor* color in self.plotColors)
		{
			[colors addObject:[[color deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15] colorWithAlphaComponent:0.5]];
		}
		
		_secondShadowLineLayer.lineColors = _shadowLineLayer.lineColors = colors;
	}
}

- (void)_updateLineColor
{
	if(self.wrapperView.effectiveAppearance.isDarkAppearance)
	{
		_secondLineLayer.lineColors = _lineLayer.lineColors = @[NSColor.whiteColor];
	}
	else
	{
		NSMutableArray<NSColor*>* colors = [NSMutableArray new];
		for(NSColor* color in self.plotColors)
		{
			[colors addObject:[color deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.3]];
		}
		
		_secondLineLayer.lineColors = _lineLayer.lineColors = colors;
	}
}

- (CPTLimitBand*)_highlightBandForRange:(CPTPlotRange *)newRange color:(NSColor*)color
{
	return [CPTLimitBand limitBandWithRange:newRange fill:[CPTFill fillWithColor:[CPTColor colorWithCGColor:[color shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.35].CGColor]]];
}

- (void)setupPlotsForGraph
{
	[self prepareSamples];
	
	NSClickGestureRecognizer* clickGestureRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(clickedByClickGestureRegonizer:)];
	[self.hostingView addGestureRecognizer:clickGestureRecognizer];
	
	NSTrackingArea* tracker = [[NSTrackingArea alloc] initWithRect:self.hostingView.bounds options:NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved owner:self userInfo:nil];
	[self.hostingView addTrackingArea:tracker];
	
	self.graph.plotAreaFrame.plotGroup = [[DTXStackedPlotGroup alloc] initForTouchBar:self.isForTouchBar];
	
	self.graph.axisSet = nil;
	
	// Setup scatter plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = YES;
	plotSpace.delegate = self;
	
	[self.plots enumerateObjectsUsingBlock:^(CPTPlot * _Nonnull plot, NSUInteger idx, BOOL * _Nonnull stop) {
		plot.delegate = self;
		[self.graph addPlot:plot];
	}];
	
	_lastDrawBounds = self.hostingView.bounds;
	
	[[self graphAnnotationsForGraph:self.graph] enumerateObjectsUsingBlock:^(CPTPlotSpaceAnnotation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[self.graph addAnnotation:obj];
	}];
	
	// Auto scale the plot space to fit the plot data
	[plotSpace scaleToFitPlots:[self.graph allPlots]];
	
	CPTPlotRange *xRange;
	if(_pendingGlobalXPlotRange)
	{
		xRange = _pendingGlobalXPlotRange;
		_pendingGlobalXPlotRange = nil;
	}
	else
	{
		xRange = [CPTPlotRange plotRangeWithLocation:@0 length:@([_document.lastRecording.defactoEndTimestamp timeIntervalSinceReferenceDate] - [_document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate])];
	}
	CPTPlotRange *yRange = [plotSpace.yRange mutableCopy];
	
	yRange = [self finessedPlotYRangeForPlotYRange:yRange];
	
	plotSpace.globalXRange = xRange;
	plotSpace.globalYRange = yRange;
	_globalYRange = yRange;
	
	plotSpace.xRange = xRange;
	plotSpace.yRange = yRange;
	
	if(_pendingXPlotRange)
	{
		plotSpace.xRange = _pendingXPlotRange;
		_pendingXPlotRange = nil;
	}
	
	__weak auto weakSelf = self;
	self.wrapperView.updateLayerHandler = ^ (NSView* view) {
		[weakSelf updateLayerHandler];
		
		[weakSelf.plots enumerateObjectsUsingBlock:^(__kindof CPTPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj reloadData];
		}];
	};
}

- (NSArray<__kindof CPTPlot *> *)plots
{
	if(_plots)
	{
		return _plots;
	}
	
	NSMutableArray* rv = [NSMutableArray new];
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		// Create the plot
		CPTScatterPlot* scatterPlot = [[DTXCPTScatterPlot alloc] initWithFrame:CGRectZero];
		scatterPlot.identifier = @(idx);
		
		// set interpolation types
		scatterPlot.interpolation = self.isStepped ? CPTScatterPlotInterpolationStepped : CPTScatterPlotInterpolationLinear;
		
		if(self.sampleKeys.count == 2 && idx == 1)
		{
			scatterPlot.transform = CATransform3DMakeScale(1.0, -1.0, 1.0);
			scatterPlot.areaBaseValue = @10000000000000000.0;
		}
		else
		{
			scatterPlot.areaBaseValue = @0.0;
		}
		
		// set data source and add plots
		scatterPlot.dataSource = self;
		
		[rv addObject:scatterPlot];
	}];
	
	_plots = rv;
	return _plots;
}

-(NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *)plot
{
	return [self samplesForPlotIndex:((NSNumber*)plot.identifier).unsignedIntegerValue].count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSUInteger plotIdx = ((NSNumber*)plot.identifier).unsignedIntegerValue;
	
	if(fieldEnum == CPTScatterPlotFieldX )
	{
		return @([[[self samplesForPlotIndex:plotIdx][index] valueForKey:@"timestamp"] timeIntervalSinceReferenceDate] - [_document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate]);
	}
	else
	{
		return [self transformedValueForFormatter:[[self samplesForPlotIndex:plotIdx][index] valueForKey:self.sampleKeys[plotIdx]]];
	}
}

-(nullable CPTPlotRange *)plotSpace:(nonnull CPTPlotSpace *)space willChangePlotRangeTo:(nonnull CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
	if(coordinate == CPTCoordinateY && _globalYRange != nil)
	{
		return _globalYRange;
	}
	
	return newRange;
}

-(void)plotSpace:(nonnull CPTPlotSpace *)space didChangePlotRangeForCoordinate:(CPTCoordinate)coordinate
{
	if(self.graph == nil || coordinate != CPTCoordinateX)
	{
		return;
	}
	
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
	[_delegate plotController:self didChangeToPlotRange:plotSpace.xRange];
}

- (void)setGlobalPlotRange:(CPTPlotRange*)globalPlotRange
{
	if(self.graph != nil)
	{
		[(CPTXYPlotSpace *)self.graph.defaultPlotSpace setGlobalXRange:globalPlotRange];
	}
	else
	{
		_pendingGlobalXPlotRange = globalPlotRange;
	}
}

- (void)setPlotRange:(CPTPlotRange *)plotRange
{
	if(self.graph != nil)
	{
		[(CPTXYPlotSpace *)self.graph.defaultPlotSpace setXRange:plotRange];
	}
	else
	{
		_pendingXPlotRange = plotRange;
	}
}

- (void)_zoomToScale:(CGFloat)scale
{
	[self.graph.defaultPlotSpace scaleBy:scale aboutPoint:CGPointMake(CGRectGetMidX(self.hostingView.bounds), CGRectGetMidY(self.hostingView.bounds))];
}

- (void)zoomIn
{
	[self _zoomToScale:2.0];
}

- (void)zoomOut
{
	[self _zoomToScale:0.5];
}

- (void)zoomToFitAllData
{
	[self.graph.defaultPlotSpace scaleToFitEntirePlots:_plots];
}

- (void)highlightSample:(id)sample
{
	[self _highlightSample:sample nextSample:nil plotSpaceOffset:0 notifyDelegate:YES];
}

- (void)shadowHighlightAtSampleTime:(NSTimeInterval)sampleTime
{
	[self _removeHighlightNotifyDelegate:NO];
	
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

- (void)_highlightSample:(DTXSample*)sample nextSample:(DTXSample*)nextSample plotSpaceOffset:(CGFloat)offset notifyDelegate:(BOOL)notify
{
	if(nextSample == nil)
	{
		offset = 0.0;
	}
	
	NSTimeInterval sampleTime = sample.timestamp.timeIntervalSinceReferenceDate - _document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate + offset;
	NSUInteger sampleIdx = [[self samplesForPlotIndex:0] indexOfObject:sample];
	NSUInteger nextSampleIdx = nextSample ? [[self samplesForPlotIndex:0] indexOfObject:nextSample] : NSNotFound;
	CGFloat percent = offset / (nextSample.timestamp.timeIntervalSinceReferenceDate - sample.timestamp.timeIntervalSinceReferenceDate);
	
	[self _highlightSampleIndex:sampleIdx nextSampleIndex:nextSampleIdx sampleTime:sampleTime percect:percent makeVisible:YES];
	
	if(notify == YES)
	{
		[self.delegate plotController:self didHighlightAtSampleTime:sampleTime];
	}
}

- (void)_highlightSampleIndex:(NSUInteger)sampleIdx nextSampleIndex:(NSUInteger)nextSampleIdx sampleTime:(NSTimeInterval)sampleTime percect:(CGFloat)percent makeVisible:(BOOL)makeVisible
{
	[self _removeHighlightNotifyDelegate:NO];
	
	_highlightedSampleIndex = sampleIdx;
	_highlightedNextSampleIndex = nextSampleIdx;
	_highlightedSampleTime = sampleTime;
	_highlightedPercent = percent;
	
	_highlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
	_lineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight + self.rangeInsets.bottom + self.rangeInsets.top)];
	[self _updateLineColor];
	_highlightAnnotation.contentLayer = _lineLayer;
	_highlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
	_highlightAnnotation.anchorPlotPoint = @[@(sampleTime), @(- self.rangeInsets.top)];
	
	NSMutableArray<NSNumber*>* dataPoints = [NSMutableArray new];
	NSMutableArray<NSColor*>* pointColors = [NSMutableArray new];
	
	NSUInteger count = self.graph.allPlots.count;
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
	
	[self.graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTScatterPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		CGFloat value = [obj plotAreaPointOfVisiblePointAtIndex:sampleIdx].y;
		if(self.isStepped == NO && nextSampleIdx != NSNotFound)
		{
			CGFloat nextValue = [obj plotAreaPointOfVisiblePointAtIndex:nextSampleIdx].y;
			
			value = [@(value) interpolateToValue:@(nextValue) progress:percent].doubleValue;
		}
		
		value += (count - 1 - idx) * (self.graph.bounds.size.height / count + 1);
		
		if(count == 2 && idx == 1)
		{
			value = (self.graph.bounds.size.height / count) - value;
		}
		
		[dataPoints addObject:@(value)];
		[pointColors addObject:self.plotColors[idx]];
	}];
	
	_lineLayer.dataPoints = dataPoints;
	_lineLayer.pointColors = pointColors;
	
	[self.graph addAnnotation:_highlightAnnotation];
	
	if(makeVisible && (sampleTime < plotSpace.xRange.location.doubleValue || sampleTime > (plotSpace.xRange.location.doubleValue + plotSpace.xRange.length.doubleValue)))
	{
		CPTMutablePlotRange* xRange = [plotSpace.xRange mutableCopy];
		xRange.location = @(MIN(MAX(sampleTime - (xRange.length.doubleValue / 2.0), plotSpace.globalXRange.location.doubleValue), plotSpace.globalXRange.location.doubleValue + plotSpace.globalXRange.length.doubleValue));
		plotSpace.xRange = xRange;
	}
}

- (void)highlightRange:(CPTPlotRange*)range
{
	[self _highlightRange:range nofityDelegate:YES];
}

- (void)shadowHighlightRange:(CPTPlotRange*)range
{
	[self _highlightRange:range nofityDelegate:NO];
}

- (void)_highlightRange:(CPTPlotRange*)range nofityDelegate:(BOOL)notifyDelegate
{
	[self _removeHighlightNotifyDelegate:NO];
	
	_highlightedRange = range;
	[self.graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTScatterPlot * _Nonnull plot, NSUInteger idx, BOOL * _Nonnull stop) {
		CPTLimitBand* band = [self _highlightBandForRange:range color:self.plotColors[idx]];
		[plot addAreaFillBand:band];
		_rangeHighlightBandArray[idx] = band;
	}];
	
	if(self.graph)
	{
		_highlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
		_lineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight + self.rangeInsets.bottom + self.rangeInsets.top)];
		if(self.isForTouchBar == NO)
		{
			_lineLayer.opacity = 0.3;
		}
		_highlightAnnotation.contentLayer = _lineLayer;
		_highlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
		_highlightAnnotation.anchorPlotPoint = @[range.location, @(- self.rangeInsets.top)];

		_secondHighlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:self.graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
		_secondLineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight + self.rangeInsets.bottom + self.rangeInsets.top)];
		if(self.isForTouchBar == NO)
		{
			_secondLineLayer.opacity = 0.3;
		}
		_secondHighlightAnnotation.contentLayer = _secondLineLayer;
		_secondHighlightAnnotation.contentAnchorPoint = CGPointMake(0.5, 0.0);
		_secondHighlightAnnotation.anchorPlotPoint = @[@(range.locationDouble + range.lengthDouble), @(- self.rangeInsets.top)];

		[self _updateLineColor];
		[self.graph addAnnotation:_highlightAnnotation];
		[self.graph addAnnotation:_secondHighlightAnnotation];
	}

	if(notifyDelegate)
	{
		[self.delegate plotController:self didHighlightRange:range];
	}
}

- (void)didFinishDrawing:(CPTPlot *)plot
{
	if(_atLeastOnce == NO || CGRectEqualToRect(_lastDrawBounds, self.hostingView.bounds) == NO)
	{
		[self reloadHighlight];
		_lastDrawBounds = self.hostingView.bounds;
		_atLeastOnce = YES;
	}
}

- (void)reloadHighlight
{
	if(_shadowHighlightedSampleTime != -1.0)
	{
		[self shadowHighlightAtSampleTime:_shadowHighlightedSampleTime];
	}
	else if(_highlightedSampleIndex != NSNotFound)
	{
		[self _highlightSampleIndex:_highlightedSampleIndex nextSampleIndex:_highlightedNextSampleIndex sampleTime:_highlightedSampleTime percect:_highlightedPercent makeVisible:NO];
	}
	else if(_highlightedRange)
	{
		[self highlightRange:_highlightedRange];
	}
	else
	{
		[self _removeHighlightNotifyDelegate:NO];
	}
}

- (void)removeHighlight
{
	[self _removeHighlightNotifyDelegate:YES];
}

- (void)_removeHighlightNotifyDelegate:(BOOL)notify
{
	BOOL hadHighlight = _lineLayer != nil;
	
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
	
	if(_highlightAnnotation && _highlightAnnotation.annotationHostLayer != nil)
	{
		[self.graph removeAnnotation:_highlightAnnotation];
	}
	
	_lineLayer = nil;
	_highlightAnnotation = nil;
	
	if(_secondHighlightAnnotation && _secondHighlightAnnotation.annotationHostLayer != nil)
	{
		[self.graph removeAnnotation:_secondHighlightAnnotation];
	}
	
	_secondLineLayer = nil;
	_secondHighlightAnnotation = nil;
	
	_highlightedSampleIndex = NSNotFound;
	_highlightedNextSampleIndex = NSNotFound;
	_highlightedSampleTime = 0.0;
	_highlightedPercent = 0.0;
	
	if(_rangeHighlightBandArray.count > 0)
	{
		[self.graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTScatterPlot * _Nonnull plot, NSUInteger idx, BOOL * _Nonnull stop) {
			CPTLimitBand* band = _rangeHighlightBandArray[idx];
			[plot removeAreaFillBand:band];
		}];
		
		[_rangeHighlightBandArray removeAllObjects];
	}
	_highlightedRange = nil;
	
	_shadowHighlightedSampleTime = -1.0;
	
	if(hadHighlight && notify)
	{
		[self.delegate plotControllerDidRemoveHighlight:self];
	}
}

- (void)noteOfSampleInsertions:(NSArray<NSNumber*>*)insertions updates:(NSArray<NSNumber*>*)updates forPlotAtIndex:(NSUInteger)index
{
	__kindof CPTPlot* plot = self.plots[index];
	
	[updates enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[plot reloadDataInIndexRange:NSMakeRange(obj.unsignedIntegerValue, 1)];
	}];
	
	__block double maxValue = 0;
	
	[[insertions sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[plot insertDataAtIndex:obj.unsignedIntegerValue numberOfRecords:1];
		double value = [[self numberForPlot:plot field:CPTScatterPlotFieldY recordIndex:obj.unsignedIntegerValue] doubleValue];
		if(value > maxValue)
		{
			maxValue = value;
		}
	}];
	
	CPTXYPlotSpace* plotSpace = (id)self.graph.defaultPlotSpace;
	CPTPlotRange* newYRange = [CPTPlotRange plotRangeWithLocation:@0 length:@(maxValue)];
	newYRange = [self finessedPlotYRangeForPlotYRange:newYRange];
	
	if(plotSpace.yRange.length.doubleValue < newYRange.length.doubleValue)
	{
		_globalYRange = newYRange;
		plotSpace.globalYRange = newYRange;
		plotSpace.yRange = newYRange;
	}
	
	[self reloadHighlight];
}

- (NSString *)displayName
{
	return @"";
}

- (NSString *)toolTip
{
	return nil;
}

- (NSImage*)displayIcon
{
	return nil;
}

- (NSImage *)smallDisplayIcon
{
	NSImage* image = [NSImage imageNamed:[NSString stringWithFormat:@"%@_small", self.displayIcon.name]];
	image.size = NSMakeSize(16, 16);
	
	return image;
}

- (NSImage *)secondaryIcon
{
    return nil;
}

- (NSFont *)titleFont
{
	return [NSFont systemFontOfSize:NSFont.systemFontSize];
}

- (CGFloat)requiredHeight
{
	return 80;
}

- (void)prepareSamples
{
	
}

- (NSArray*)samplesForPlotIndex:(NSUInteger)index
{
	return @[];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[];
}

- (NSArray<NSString *>*)plotTitles
{
	return @[];
}

- (CGFloat)yRangeMultiplier;
{
	return 1.15;
}

- (NSArray<CPTPlotSpaceAnnotation*>*)graphAnnotationsForGraph:(CPTGraph*)graph
{
	return @[];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_stringFormatter];
}

- (NSEdgeInsets)rangeInsets
{
	return NSEdgeInsetsZero;
}

- (id)transformedValueForFormatter:(id)value
{
	return value;
}

- (BOOL)isStepped
{
	return NO;
}

- (BOOL)canReceiveFocus
{
	return YES;
}

- (NSArray<NSString *> *)legendTitles
{
	return self.plotTitles;
}

- (NSArray<NSColor *> *)legendColors
{
	return self.plotColors;
}

@end
