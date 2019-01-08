//
//  DTXPieChartView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPieChartView.h"
#import <CorePlot/CorePlot.h>
#import "DTXGraphHostingView.h"
#import "NSColor+UIAdditions.h"

@implementation DTXPieChartEntry

+ (instancetype)entryWithValue:(NSNumber *)value title:(NSString *)title color:(NSColor *)color
{
	DTXPieChartEntry* rv = [[self class] new];
	
	if(rv != nil)
	{
		rv->_value = value;
		rv->_title = [title copy];
		rv->_color = color;
	}
	
	return rv;
}

@end

@interface DTXPieChartView () <CPTPieChartDataSource> @end

@implementation DTXPieChartView
{
	DTXGraphHostingView* _host;
	CPTGraph* _graph;
	CPTPieChart* _chart;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth = 0.5;
	lineStyle.lineColor = [CPTColor colorWithCGColor:NSColor.labelColor.CGColor];
	
	_chart.borderLineStyle = lineStyle;
	_chart.backgroundColor = NSColor.clearColor.CGColor;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		_chart = [[CPTPieChart alloc] init];
		_chart.dataSource = self;
		_chart.pieRadius = 80;
		_chart.pieInnerRadius = 40;
		_chart.startAngle = CPTFloat(M_PI_4);
		_chart.sliceDirection = CPTPieDirectionClockwise;

		_graph = [[CPTXYGraph alloc] initWithFrame:self.bounds];
		[_graph addPlot:_chart];

		_graph.axisSet = nil;
		_graph.backgroundColor = NSColor.clearColor.CGColor;
		_graph.paddingLeft = 0;
		_graph.paddingTop = 0;
		_graph.paddingRight = 0;
		_graph.paddingBottom = 0;
		_graph.masksToBorder  = NO;

		_host = [[DTXGraphHostingView alloc] initWithFrame:self.bounds];
		_host.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:_host];

		[NSLayoutConstraint activateConstraints:@[[_host.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
												  [_host.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
												  [_host.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
												  [_host.topAnchor constraintEqualToAnchor:self.topAnchor]]];

		[_graph.defaultPlotSpace scaleToFitPlots:[_graph allPlots]];

		_host.hostedGraph = _graph;
	}
	
	return self;
}

-(NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *)plot
{
	return _entries.count;
}

-(id)numberForPlot:(nonnull CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
	if(fieldEnum == CPTPieChartFieldSliceWidth)
	{
		return _entries[idx].value;
	}
	
	return nil;
}

-(nullable CPTFill *)sliceFillForPieChart:(nonnull CPTPieChart *)pieChart recordIndex:(NSUInteger)idx
{
	CPTColor* sliceColor = [CPTColor colorWithCGColor:[NSColor randomColorWithSeed:_entries[idx].title].CGColor];
	return   [CPTFill fillWithColor:sliceColor];
}

- (CGFloat)radialOffsetForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)idx
{
	return idx == _highlightedEntry ? 10 : 0;
}

- (void)setEntries:(NSArray<DTXPieChartEntry *> *)entries highlightedEntry:(NSUInteger)highlightedEntry
{
	_entries = [entries copy];
	_highlightedEntry = highlightedEntry;
	
	[_chart reloadData];
}

- (void)mouseDown:(NSEvent *)event
{
	//Ignore mouse down on ugnore
}

- (void)mouseUp:(NSEvent *)event
{
	//Ignore mouse up on ugnore
}

@end
