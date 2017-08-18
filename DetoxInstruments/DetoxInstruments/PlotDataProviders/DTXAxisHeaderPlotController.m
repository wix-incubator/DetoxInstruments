//
//  DTXAxisHeaderPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXAxisHeaderPlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXGraphHostingView.h"
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXRecording+UIExtensions.h"

@interface DTXAxisHeaderPlotController ()

@end

@implementation DTXAxisHeaderPlotController
{
	CPTGraphHostingView* _hostingView;
	CPTGraph* _graph;
	CPTPlotRange* _pendingGlobalXPlotRange;
	CPTPlotRange* _pendingXPlotRange;
	CPTMutablePlotRange* _globalYRange;
}

@synthesize delegate = _delegate;
@synthesize document = _document;
@synthesize dataProvider = _dataProvider;

-(CGFloat)titleSize
{
	return 24;
}

- (instancetype)initWithDocument:(DTXDocument*)document
{
	self = [super init];
	
	if(self)
	{
		_document = document;
	}
	
	return self;
}

- (void)dealloc
{
	[_hostingView removeFromSuperview];
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
		_hostingView.frame = view.bounds;
	}
	else
	{
		_hostingView = [[DTXGraphHostingView alloc] initWithFrame:view.bounds];
		_hostingView.translatesAutoresizingMaskIntoConstraints = NO;
		
		CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:_hostingView.bounds];
		
		graph.paddingLeft = 0;
		graph.paddingTop = 0;
		graph.paddingRight = 0;
		graph.paddingBottom = 0;
		graph.masksToBorder  = NO;
		
		// Setup scatter plot space
		CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
		if(_pendingGlobalXPlotRange)
		{
			plotSpace.globalXRange = _pendingGlobalXPlotRange;
			_pendingGlobalXPlotRange = nil;
		}
		else
		{
			plotSpace.globalXRange = plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@0 length:@([_document.recording.defactoEndTimestamp timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate])];
		}
		plotSpace.globalYRange = plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@0.5 length:@5.0];
		
		if(_pendingXPlotRange)
		{
			plotSpace.xRange = _pendingXPlotRange;
			_pendingXPlotRange = nil;
		}
		
		const CGFloat majorTickLength = 20;
		const CGFloat minorTickLength = 6.0;
		
		CPTMutableLineStyle* axisLineStyle = [CPTMutableLineStyle lineStyle];
		axisLineStyle.lineColor = [CPTColor colorWithCGColor:[NSColor grayColor].CGColor];
		axisLineStyle.lineWidth = 0.5;
		axisLineStyle.lineCap   = kCGLineCapRound;
		
		CPTMutableTextStyle* labelStyle = [CPTMutableTextStyle textStyle];
		labelStyle.color = axisLineStyle.lineColor;
		labelStyle.fontName = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightMedium].fontName;
		labelStyle.fontSize = 11;
		
		// Axes
		
		// CPTAxisLabelingPolicyAutomatic
		CPTXYAxis *axisAutomatic = [[CPTXYAxis alloc] init];
		axisAutomatic.plotSpace = graph.defaultPlotSpace;
		axisAutomatic.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
		axisAutomatic.preferredNumberOfMajorTicks = 10;
		axisAutomatic.orthogonalPosition = @0.0;
		axisAutomatic.minorTicksPerInterval = 9;
		axisAutomatic.tickDirection = CPTSignPositive;
		axisAutomatic.axisLineStyle = axisLineStyle;
		axisAutomatic.majorTickLength = majorTickLength;
		axisAutomatic.majorTickLineStyle = axisLineStyle;
		axisAutomatic.minorTickLength = minorTickLength;
		axisAutomatic.minorTickLineStyle = axisLineStyle;
		axisAutomatic.labelFormatter = [NSFormatter dtx_secondsFormatter];
		axisAutomatic.labelAlignment = CPTAlignmentLeft;
		axisAutomatic.tickLabelDirection = CPTSignPositive;
		axisAutomatic.labelOffset = -(majorTickLength * 6 / 8);
		axisAutomatic.labelTextStyle = labelStyle;
		
		// Add axes to the graph
		graph.axisSet.axes = @[axisAutomatic];
		
		_graph = graph;
	
		_hostingView.hostedGraph = _graph;
	}
	
	[view addSubview:_hostingView];
	
	[NSLayoutConstraint activateConstraints:@[[view.topAnchor constraintEqualToAnchor:_hostingView.topAnchor constant:-insets.top],
											  [view.leadingAnchor constraintEqualToAnchor:_hostingView.leadingAnchor constant:-insets.left],
											  [view.trailingAnchor constraintEqualToAnchor:_hostingView.trailingAnchor constant:-insets.right],
											  [view.bottomAnchor constraintEqualToAnchor:_hostingView.bottomAnchor constant:-insets.bottom]]];
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

- (void)zoomIn
{
	
}

- (void)zoomOut
{
	
}

- (void)setGlobalPlotRange:(CPTPlotRange*)globalPlotRange
{
	if(_graph != nil)
	{
		[(CPTXYPlotSpace *)_graph.defaultPlotSpace setGlobalXRange:globalPlotRange];
	}
	else
	{
		_pendingGlobalXPlotRange = globalPlotRange;
	}
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

- (NSString *)displayName
{
	return @"";
}

- (NSImage*)displayIcon
{
	return nil;
}

- (NSImage *)secondaryIcon
{
    return nil;
}

- (NSFont *)titleFont
{
	return nil;
}

- (CGFloat)requiredHeight
{
	return 18;
}

@end
