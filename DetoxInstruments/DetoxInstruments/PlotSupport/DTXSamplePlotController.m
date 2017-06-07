//
//  DTXSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSamplePlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"

static NSColor* __DTXDarkerColorFromColor(NSColor* color)
{
	return [color blendedColorWithFraction:0.3 ofColor:NSColor.blackColor];
}

static NSColor* __DTXLighterColorFromColor(NSColor* color)
{
	return [color blendedColorWithFraction:0.15 ofColor:NSColor.whiteColor];
}

@interface DTXSamplePlotController () <CPTScatterPlotDataSource, CPTPlotSpaceDelegate>

@end

@implementation DTXSamplePlotController
{
	NSArray<NSArray<NSDictionary<NSString*, id>*>*>* _samples;
	CPTGraph* _graph;
	CPTGraphHostingView* _hostingView;
	CPTMutablePlotRange* _globalYRange;
	
	NSStoryboard* _scene;
	
//	CPTPlotSpaceAnnotation* _cursorAnnotation;
}

@synthesize delegate = _delegate;

- (instancetype)initWithDocument:(DTXDocument*)document
{
	self = [super init];

	if(self)
	{
		_document = document;
		_samples = [self samplesForPlots];
		_scene = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
	}
	
	return self;
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

- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets
{
	if(_hostingView)
	{
		[_hostingView removeFromSuperview];
		_hostingView = nil;
	}
	
	_hostingView = [[CPTGraphHostingView alloc] initWithFrame:view.bounds];
	_hostingView.translatesAutoresizingMaskIntoConstraints = NO;
	[view addSubview:_hostingView];
	
	[NSLayoutConstraint activateConstraints:@[[view.topAnchor constraintEqualToAnchor:_hostingView.topAnchor constant:insets.top],
											  [view.leadingAnchor constraintEqualToAnchor:_hostingView.leadingAnchor constant:insets.left],
											  [view.trailingAnchor constraintEqualToAnchor:_hostingView.trailingAnchor constant:insets.right],
											  [view.bottomAnchor constraintEqualToAnchor:_hostingView.bottomAnchor constant:insets.bottom]]];
	
	NSTrackingArea* tracker = [[NSTrackingArea alloc] initWithRect:_hostingView.bounds options:NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved owner:self userInfo:nil];
	[_hostingView addTrackingArea:tracker];
	
	if(_graph == nil)
	{
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
		
		NSArray<NSColor*>* plotColors = self.plotColors;
		
		[_samples enumerateObjectsUsingBlock:^(NSArray<NSDictionary<NSString *,id> *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			// Create the plot
			CPTScatterPlot *plot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
			plot.identifier = @(idx);
			
			// set interpolation types
			plot.interpolation = self.isStepped ? CPTScatterPlotInterpolationStepped : CPTScatterPlotInterpolationLinear;
			
			plot.curvedInterpolationOption = CPTScatterPlotCurvedInterpolationCatmullRomCentripetal;
			
			// style plots
			CPTMutableLineStyle *lineStyle = [plot.dataLineStyle mutableCopy];
			lineStyle.lineWidth = 1.0;
			lineStyle.lineColor = [CPTColor colorWithCGColor:__DTXDarkerColorFromColor(plotColors[idx]).CGColor];
			plot.dataLineStyle = lineStyle;
			plot.areaFill = [CPTFill fillWithColor:[CPTColor colorWithCGColor:__DTXLighterColorFromColor(plotColors[idx]).CGColor]];
			plot.areaBaseValue = @0.0;
			
			// set data source and add plots
			plot.dataSource = self;
			
			[graph addPlot:plot];
		}];
		
		// Auto scale the plot space to fit the plot data
		[plotSpace scaleToFitPlots:[graph allPlots]];
		CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:@0 length:@([_document.recording.endTimestamp timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate])];
		CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
		yRange.length = @(yRange.length.doubleValue * 1.15);
		
		plotSpace.globalXRange = xRange;
		plotSpace.globalYRange = yRange;
		_globalYRange = yRange;
		
		plotSpace.xRange = xRange;
		plotSpace.yRange = yRange;
	
		_graph = graph;
	}
	
	_hostingView.hostedGraph = _graph;
}

-(NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *)plot
{
	return _samples[((NSNumber*)plot.identifier).unsignedIntegerValue].count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	if(fieldEnum == CPTScatterPlotFieldX )
	{
		return @([_samples[((NSNumber*)plot.identifier).unsignedIntegerValue][index][@"timestamp"] timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate]);
	}
	else
	{
		return _samples[((NSNumber*)plot.identifier).unsignedIntegerValue][index][self.sampleKeys[((NSNumber*)plot.identifier).unsignedIntegerValue]];
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
	[(CPTXYPlotSpace *)_graph.defaultPlotSpace setXRange:plotRange];
}

- (NSString *)displayName
{
	return @"";
}

- (NSImage*)displayIcon
{
	return nil;
}

- (CGFloat)requiredHeight
{
	return 80;
}

- (NSArray<NSArray<NSDictionary<NSString*, id>*>*>*)samplesForPlots
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

- (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_stringFormatter];
}

- (id)transformedValueForFormatter:(id)value
{
	return value;
}

- (BOOL)isStepped
{
	return NO;
}

@end
