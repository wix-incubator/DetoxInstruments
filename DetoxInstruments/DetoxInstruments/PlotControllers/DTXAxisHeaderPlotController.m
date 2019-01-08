//
//  DTXAxisHeaderPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXAxisHeaderPlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXCPTXYAxis.h"

@interface DTXAxisHeaderPlotController () <CPTPlotSpaceDelegate>

@end

@implementation DTXAxisHeaderPlotController
{
	CPTPlotRange* _pendingGlobalXPlotRange;
	CPTPlotRange* _pendingXPlotRange;
	CPTMutablePlotRange* _globalYRange;
}

@synthesize delegate = _delegate;
@synthesize document = _document;
@dynamic dataProviderControllers, helpTopicName;

-(CGFloat)titleSize
{
	return 0;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super init];
	
	if(self)
	{
		_document = document;
	}
	
	return self;
}

- (BOOL)usesInternalPlots
{
	return NO;
}

- (void)setupPlotsForGraph
{
	// Setup scatter plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
	plotSpace.delegate = self;
	if(_pendingGlobalXPlotRange)
	{
		plotSpace.globalXRange = _pendingGlobalXPlotRange;
		_pendingGlobalXPlotRange = nil;
	}
	else
	{
		plotSpace.globalXRange = plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@0 length:@([_document.lastRecording.defactoEndTimestamp timeIntervalSinceReferenceDate] - [_document.firstRecording.startTimestamp timeIntervalSinceReferenceDate])];
	}
	plotSpace.globalYRange = plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@0.5 length:@5.0];
	
	if(_pendingXPlotRange)
	{
		plotSpace.xRange = _pendingXPlotRange;
		_pendingXPlotRange = nil;
	}
	
	const CGFloat majorTickLength = 30;
	const CGFloat minorTickLength = 6.0;
	
	__weak auto weakSelf = self;
	
	self.graph.backgroundColor = NSColor.clearColor.CGColor;
	
	self.wrapperView.updateLayerHandler = ^ (NSView* view) {
		CPTMutableLineStyle* axisLineStyle = [CPTMutableLineStyle lineStyle];
		axisLineStyle.lineColor = [CPTColor colorWithCGColor:NSColor.gridColor.CGColor];
		axisLineStyle.lineWidth = 1.0;
		axisLineStyle.lineCap   = kCGLineCapButt;
		
		CPTMutableTextStyle* labelStyle = [CPTMutableTextStyle textStyle];
		labelStyle.color = [CPTColor colorWithCGColor:NSColor.tertiaryLabelColor.CGColor];
		labelStyle.fontName = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular].fontName;
		labelStyle.fontSize = 11;
		
		// Axes
		
		// CPTAxisLabelingPolicyAutomatic
		CPTXYAxis *axisAutomatic = [[DTXCPTXYAxis alloc] init];
		axisAutomatic.plotSpace = weakSelf.graph.defaultPlotSpace;
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
		axisAutomatic.labelOffset = -(majorTickLength * 6.5 / 8);
		axisAutomatic.labelTextStyle = labelStyle;
		
		// Add axes to the graph
		weakSelf.graph.axisSet.axes = @[axisAutomatic];
	};
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

- (void)zoomIn {}
- (void)zoomOut {}
- (void)zoomToFitAllData {}


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

- (NSImage*)smallDisplayIcon
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
	return 20;
}

- (NSArray<NSColor *> *)legendColors
{
	return @[];
}

- (NSArray<NSString *> *)legendTitles
{
	return @[];
}

@end
