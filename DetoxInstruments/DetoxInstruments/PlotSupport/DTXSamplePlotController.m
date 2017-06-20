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

static NSColor* __DTXDarkerColorFromColor(NSColor* color)
{
	return [color blendedColorWithFraction:0.3 ofColor:NSColor.blackColor];
}

static NSColor* __DTXLighterColorFromColor(NSColor* color)
{
	return [color blendedColorWithFraction:0.15 ofColor:NSColor.whiteColor];
}

@interface DTXSamplePlotController ()

@end

@implementation DTXSamplePlotController
{
	CPTGraph* _graph;
	__kindof CPTGraphHostingView* _hostingView;
	CPTMutablePlotRange* _globalYRange;
	CPTPlotRange* _pendingXPlotRange;
	
	NSStoryboard* _scene;
	
//	CPTPlotSpaceAnnotation* _cursorAnnotation;
	NSMutableDictionary<id, CPTPlotSpaceAnnotation*>* _highlightAnnotations;
	NSMutableDictionary<id, DTXLineLayer*>* _lineLayers;
}

@synthesize delegate = _delegate;
@synthesize document = _document;
@synthesize dataProvider = _dataProvider;
@synthesize samples = _samples;

+ (Class)graphHostingViewClass
{
	return [DTXGraphHostingView class];
}

+ (Class)UIDataProviderClass
{
	return nil;
}

- (instancetype)initWithDocument:(DTXDocument*)document
{
	self = [super init];

	if(self)
	{
		_document = document;
		_scene = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
		_dataProvider = [[[self.class UIDataProviderClass] alloc] initWithDocument:_document plotController:self];
	}
	
	return self;
}

- (NSArray<NSArray *> *)samples
{
	if(_samples == nil)
	{
		_samples = [self samplesForPlots];
	}
	
	return _samples;
}

- (void)mouseEntered:(NSEvent *)event
{
//	CGPoint pointInView = [_hostingView convertPoint:[event locationInWindow] fromView:nil];
//	CPTNumberArray* plotPoint = [_graph.defaultPlotSpace plotPointForPlotAreaViewPoint:pointInView];
	
//	if(_cursorAnnotation == nil)
//	{
//		CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:@"aa" style:[CPTTextStyle textStyle]];
//		
//		_cursorAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:_graph.defaultPlotSpace anchorPlotPoint:pt];
//		_cursorAnnotation.contentLayer = textLayer;
//		[_graph addAnnotation:_cursorAnnotation];
//	}

}

- (void)mouseExited:(NSEvent *)event
{
//	[_graph removeAnnotation:_cursorAnnotation];
//	_cursorAnnotation = nil;
	[_hostingView removeAllToolTips];
}

- (void)mouseMoved:(NSEvent *)event
{
	CGPoint pointInView = [_hostingView convertPoint:[event locationInWindow] fromView:nil];
//	CPTNumberArray* plotPoint = [_graph.defaultPlotSpace plotPointForPlotAreaViewPoint:pointInView];
	
	NSMutableArray<NSDictionary<NSString*, NSString*>*>* dataPoints = [NSMutableArray new];
	
	[_graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSUInteger numberOfRecords = [self numberOfRecordsForPlot:obj];
		NSUInteger foundPointIndex = 0;
		for(NSUInteger idx = 0; idx < numberOfRecords; idx++)
		{
			CGPoint pointOfPoint = [obj plotAreaPointOfVisiblePointAtIndex:idx];
			if(pointOfPoint.x < pointInView.x)
			{
				foundPointIndex = idx;
			}
			else
			{
				break;
			}
		}
		
		id y = [self numberForPlot:obj field:CPTScatterPlotFieldY recordIndex:foundPointIndex];
		
		[dataPoints addObject:@{@"title":self.plotTitles[idx], @"data": [[self formatterForDataPresentation] stringForObjectValue:[self transformedValueForFormatter:y]]}];
	}];
	
	if(dataPoints.count == 0)
	{
		return;
	}
	
	[_hostingView removeAllToolTips];
	if(dataPoints.count == 1)
	{
		[_hostingView setToolTip:dataPoints.firstObject[@"data"]];
	}
	else
	{
		NSMutableString* tooltip = [NSMutableString new];
		[dataPoints enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[tooltip appendString:[NSString stringWithFormat:@"%@: %@\n", obj[@"title"], obj[@"data"]]];
		}];
		
		[_hostingView setToolTip:[tooltip stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
	}
//
//	_cursorAnnotation.anchorPlotPoint = @[plotPoint.firstObject, y];
}

- (void)setUpWithView:(NSView *)view
{
	[self setUpWithView:view insets:NSEdgeInsetsZero];
}

- (void)_clicked:(NSClickGestureRecognizer*)cgr
{
	if(self.canReceiveFocus == NO)
	{
		return;
	}
	
	[self.delegate plotControllerUserDidClickInPlotBounds:self];
	
	NSPoint pointInView = [cgr locationInView:_hostingView];
	
	NSUInteger numberOfRecords = [self numberOfRecordsForPlot:self.plots.firstObject];
	NSUInteger foundPointIndex = 0;
	for(NSUInteger idx = 0; idx < numberOfRecords; idx++)
	{
		CGPoint pointOfPoint = [(CPTScatterPlot*)_graph.allPlots.firstObject plotAreaPointOfVisiblePointAtIndex:idx];
		if(pointOfPoint.x < pointInView.x)
		{
			foundPointIndex = idx;
		}
		else
		{
			break;
		}
	}
	
	id sample = self.samples[((NSNumber*)self.plots.firstObject.identifier).unsignedIntegerValue][foundPointIndex];
	
	[_dataProvider selectSample:sample];
}

- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets
{
	if(_hostingView)
	{
		[_hostingView removeFromSuperview];
		_hostingView.frame = view.bounds;
	}
	else
	{
		_hostingView = [[[self.class graphHostingViewClass] alloc] initWithFrame:view.bounds];
		_hostingView.translatesAutoresizingMaskIntoConstraints = NO;
		
		NSClickGestureRecognizer* clickGestureRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_clicked:)];
		[_hostingView addGestureRecognizer:clickGestureRecognizer];
		
		NSTrackingArea* tracker = [[NSTrackingArea alloc] initWithRect:_hostingView.bounds options:NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved owner:self userInfo:nil];
		[_hostingView addTrackingArea:tracker];
		
		CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:_hostingView.bounds];
		graph.axisSet = nil;
		graph.backgroundColor = [NSColor whiteColor].CGColor;
		
		graph.paddingLeft = 0;
		graph.paddingTop = 0;
		graph.paddingRight = 0;
		graph.paddingBottom = 0;
		graph.masksToBorder  = YES;
		
		// Setup scatter plot space
		CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
		plotSpace.allowsUserInteraction = YES;
		plotSpace.delegate = self;
		
		[self.plots enumerateObjectsUsingBlock:^(CPTPlot * _Nonnull plot, NSUInteger idx, BOOL * _Nonnull stop) {
			[graph addPlot:plot];
		}];
		
		[[self graphAnnotationsForGraph:graph] enumerateObjectsUsingBlock:^(CPTPlotSpaceAnnotation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[graph addAnnotation:obj];
		}];
		
		// Auto scale the plot space to fit the plot data
		[plotSpace scaleToFitPlots:[graph allPlots]];
		
		CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:@0 length:@([_document.recording.endTimestamp timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate])];
		CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
		
		NSEdgeInsets insets = self.rangeInsets;
		
		CGFloat initial = yRange.location.doubleValue;
		yRange.location = @(-insets.bottom);
		yRange.length = @((initial + yRange.length.doubleValue + insets.top + insets.bottom) * self.yRangeMultiplier);
		
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
		
		_graph = graph;
		
		_hostingView.hostedGraph = _graph;
	}
	
	[view addSubview:_hostingView];
	
	[NSLayoutConstraint activateConstraints:@[[view.topAnchor constraintEqualToAnchor:_hostingView.topAnchor constant:insets.top],
											  [view.leadingAnchor constraintEqualToAnchor:_hostingView.leadingAnchor constant:insets.left],
											  [view.trailingAnchor constraintEqualToAnchor:_hostingView.trailingAnchor constant:insets.right],
											  [view.bottomAnchor constraintEqualToAnchor:_hostingView.bottomAnchor constant:insets.bottom]]];
}

- (NSArray<CPTPlot *> *)plots
{
	NSArray<NSColor*>* plotColors = self.plotColors;
	
	NSMutableArray* rv = [NSMutableArray new];
	[self.samples enumerateObjectsUsingBlock:^(NSArray<NSDictionary<NSString *,id> *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		// Create the plot
		CPTScatterPlot* scatterPlot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
		scatterPlot.identifier = @(idx);
		
		// set interpolation types
		scatterPlot.interpolation = self.isStepped ? CPTScatterPlotInterpolationStepped : CPTScatterPlotInterpolationLinear;
		
		scatterPlot.curvedInterpolationOption = CPTScatterPlotCurvedInterpolationCatmullRomCentripetal;
		
		// style plots
		CPTMutableLineStyle *lineStyle = [scatterPlot.dataLineStyle mutableCopy];
		lineStyle.lineWidth = 1.0;
		lineStyle.lineColor = [CPTColor colorWithCGColor:__DTXDarkerColorFromColor(plotColors[idx]).CGColor];
		scatterPlot.dataLineStyle = lineStyle;
		
		CPTGradient* gradient = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:__DTXLighterColorFromColor(plotColors[idx]).CGColor] endingColor:[CPTColor colorWithCGColor:__DTXLighterColorFromColor(__DTXLighterColorFromColor(plotColors[idx])).CGColor]];
		gradient.gradientType = CPTGradientTypeAxial;
		gradient.angle = -90;
		
		scatterPlot.areaFill = [CPTFill fillWithGradient:gradient];
		scatterPlot.areaBaseValue = @0.0;
		
		// set data source and add plots
		scatterPlot.dataSource = self;
		
		[rv addObject:scatterPlot];
	}];
	
	return rv;
}

-(NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *)plot
{
	return self.samples[((NSNumber*)plot.identifier).unsignedIntegerValue].count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	if(fieldEnum == CPTScatterPlotFieldX )
	{
		return @([[self.samples[((NSNumber*)plot.identifier).unsignedIntegerValue][index] valueForKey:@"timestamp"] timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate]);
	}
	else
	{
		return [self transformedValueForFormatter:[self.samples[((NSNumber*)plot.identifier).unsignedIntegerValue][index] valueForKey:self.sampleKeys[((NSNumber*)plot.identifier).unsignedIntegerValue]]];
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
	if(_graph == nil || coordinate != CPTCoordinateX)
	{
		return;
	}
	
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
	[_delegate plotController:self didChangeToPlotRange:plotSpace.xRange];
}

- (void)setPlotRange:(CPTPlotRange *)plotRange
{
	if(_graph != nil)
	{
		[(CPTXYPlotSpace *)_graph.defaultPlotSpace setXRange:plotRange];
	}
	else
	{
		_pendingXPlotRange = plotRange;
	}
}

- (void)highlightSample:(DTXSample*)sample
{
	if(_highlightAnnotations == nil)
	{
		_highlightAnnotations = [NSMutableDictionary new];
		_lineLayers = [NSMutableDictionary new];
	}
	
	NSTimeInterval sampleTime = [sample.timestamp timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSUInteger sampleIdx = [_samples.firstObject indexOfObject:sample];
	
	[_graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTScatterPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		CGFloat value = [obj plotAreaPointOfVisiblePointAtIndex:sampleIdx].y;
		
		CPTPlotSpaceAnnotation* highlightAnnotation = _highlightAnnotations[obj.identifier];
		DTXLineLayer* lineLayer = _lineLayers[obj.identifier];
		if(highlightAnnotation == nil)
		{
			highlightAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:_graph.defaultPlotSpace anchorPlotPoint:@[@0, @0]];
			lineLayer = [[DTXLineLayer alloc] initWithFrame:CGRectMake(0, 0, 15, self.requiredHeight)];
			lineLayer.lineColor = __DTXDarkerColorFromColor(__DTXDarkerColorFromColor(self.plotColors[idx])).CGColor;
			highlightAnnotation.contentLayer = lineLayer;
			highlightAnnotation.contentAnchorPoint = CGPointMake(0.5 * ((idx + 1) / (CGFloat)_graph.allPlots.count), 0.0);
			[_graph addAnnotation:highlightAnnotation];
			
			_highlightAnnotations[obj.identifier] = highlightAnnotation;
			_lineLayers[obj.identifier] = lineLayer;
		}
		
		highlightAnnotation.anchorPlotPoint = @[@(sampleTime), @0];
		lineLayer.dataPoint = value;
	}];
	
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
	if(sampleTime < plotSpace.xRange.location.doubleValue || sampleTime > (plotSpace.xRange.location.doubleValue + plotSpace.xRange.length.doubleValue))
	{
		CPTMutablePlotRange* xRange = [plotSpace.xRange mutableCopy];
		xRange.location = @(MIN(MAX(sampleTime - (xRange.length.doubleValue / 2.0), plotSpace.globalXRange.location.doubleValue), plotSpace.globalXRange.location.doubleValue + plotSpace.globalXRange.length.doubleValue));
		plotSpace.xRange = xRange;
	}
}

- (void)removeHighlight
{
	[_highlightAnnotations enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, CPTPlotSpaceAnnotation * _Nonnull obj, BOOL * _Nonnull stop) {
		[_graph removeAnnotation:obj];
	}];
	
	_lineLayers = nil;
	_highlightAnnotations = nil;
}

- (NSString *)displayName
{
	return @"";
}

- (NSImage*)displayIcon
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

- (NSArray<NSArray *> *)samplesForPlots
{
	return nil;
}

- (NSArray<NSString*>*)sampleKeys
{
	return nil;
}

- (NSArray<NSColor*>*)plotColors
{
	return nil;
}

- (NSArray<NSString *> *)plotTitles
{
	return nil;
}

- (CGFloat)yRangeMultiplier;
{
	return 1.15;
}

- (NSArray<CPTPlotSpaceAnnotation*>*)graphAnnotationsForGraph:(CPTGraph*)graph
{
	return @[];
}

- (NSFormatter*)formatterForDataPresentation
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

@end
