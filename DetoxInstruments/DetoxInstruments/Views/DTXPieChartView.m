//
//  DTXPieChartView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPieChartView.h"
#import <CorePlot/CorePlot.h>
#import "DTXGraphHostingView.h"

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

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		_chart = [[CPTPieChart alloc] initWithFrame:self.bounds];
		_chart.dataSource = self;
		_chart.pieRadius = 300;
		
		CPTMutableLineStyle *whiteLineStyle = [CPTMutableLineStyle lineStyle];
		whiteLineStyle.lineColor = [CPTColor whiteColor];
		
		CPTMutableShadow *whiteShadow = [CPTMutableShadow shadow];
		whiteShadow.shadowOffset     = CGSizeMake(2.0, -4.0);
		whiteShadow.shadowBlurRadius = 4.0;
		whiteShadow.shadowColor      = [[CPTColor whiteColor] colorWithAlphaComponent:0.25];
		
		_chart.pieInnerRadius  = _chart.pieRadius + 5.0;
		_chart.borderLineStyle = whiteLineStyle;
		_chart.startAngle      = M_PI_4;
		_chart.endAngle        = 3.0 * M_PI_4;
		_chart.sliceDirection  = CPTPieDirectionCounterClockwise;
		
		_graph = [[CPTXYGraph alloc] initWithFrame:self.bounds];
		[_graph addPlot:_chart];
		
		_graph.axisSet = nil;
		
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
		return _entries[idx];
	}
	
	return @(idx);
}

-(nullable CPTFill *)sliceFillForPieChart:(nonnull CPTPieChart *)pieChart recordIndex:(NSUInteger)idx
{
	return [CPTFill fillWithColor:[CPTColor colorWithCGColor:_entries[idx].color.CGColor]];
}

- (void)setEntries:(NSArray<DTXPieChartEntry*>*)entries
{
	_entries = [entries copy];
	
	[_chart reloadData];
}

@end
