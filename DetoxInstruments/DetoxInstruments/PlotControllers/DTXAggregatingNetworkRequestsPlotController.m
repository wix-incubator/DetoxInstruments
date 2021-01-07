//
//  DTXAggregatingNetworkRequestsPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 13/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXAggregatingNetworkRequestsPlotController.h"
#import <CorePlot/CorePlot.h>
#import <LNInterpolation/LNInterpolation.h>
#import "DTXNetworkSample+CoreDataClass.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXGraphHostingView.h"
#import "DTXNetworkDataProvider.h"
#import "DTXCPTRangePlot.h"

@interface _DTXNetworkSampleAggregate : NSObject

@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSDate* responseTimestamp;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) CGFloat plotHeight;

@end

@implementation _DTXNetworkSampleAggregate @end

@implementation DTXAggregatingNetworkRequestsPlotController
{
	NSMutableArray<_DTXNetworkSampleAggregate*>* _aggregates;
	CGFloat _requiredHeight;
	CGFloat _maxWidth;
	NSColor* _startColor;
	NSColor* _endColor;
}

+ (Class)graphHostingViewClass
{
	return [DTXInvertedGraphHostingView class];
}

+ (Class)UIDataProviderClass
{
	return [DTXNetworkDataProvider class];
}

- (NSArray<NSArray<NSDictionary<NSString*, id>*>*>*)samplesForPlots
{
	if(_aggregates == nil)
	{
		_aggregates = [NSMutableArray new];
	}
	
	_startColor = self.plotColors.firstObject;
	_endColor = [self.plotColors.firstObject interpolateToValue:NSColor.warning3Color progress:0.5];
	
	NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	NSArray<DTXNetworkSample*>* results = [self.document.recording.managedObjectContext executeFetchRequest:fr error:NULL];
	
	[results enumerateObjectsUsingBlock:^(DTXNetworkSample * _Nonnull currentSample, NSUInteger idx, BOOL * _Nonnull stop) {
		
		NSDate* timestamp = currentSample.timestamp;
		
		__block _DTXNetworkSampleAggregate* _targetAggregate = nil;
		
		[_aggregates enumerateObjectsUsingBlock:^(_DTXNetworkSampleAggregate* _Nonnull possibleAggregate, NSUInteger idx, BOOL * _Nonnull stop) {
			NSDate* lastResponseTimestamp = possibleAggregate.responseTimestamp;
			if(lastResponseTimestamp == nil)
			{
				lastResponseTimestamp = [NSDate distantFuture];
			}
			
			if([timestamp compare:lastResponseTimestamp] == NSOrderedAscending)
			{
				_targetAggregate = possibleAggregate;
				*stop = YES;
			}
		}];
		
		if(_targetAggregate == nil)
		{
			_targetAggregate = [_DTXNetworkSampleAggregate new];
			_targetAggregate.timestamp = currentSample.timestamp;
			_targetAggregate.responseTimestamp = currentSample.responseTimestamp;
			_targetAggregate.lineWidth = 1;
			_targetAggregate.plotHeight = _aggregates.count == 0 ? 0.0 : _aggregates.lastObject.plotHeight + 1;
			
			[_aggregates addObject:_targetAggregate];
		}
		else
		{
			_targetAggregate.lineWidth += 0.15;
			
			_maxWidth = MAX(_maxWidth, _targetAggregate.lineWidth);
			
			if([_targetAggregate.responseTimestamp compare:currentSample.responseTimestamp] == NSOrderedAscending)
			{
				_targetAggregate.responseTimestamp = currentSample.responseTimestamp;
			}
		}
		
		_requiredHeight += 0.5;
	}];
	
	return @[];
}

- (NSArray<CPTPlot *> *)plots
{
	// Create a plot that uses the data source method
	CPTRangePlot *dataSourceLinePlot = [[DTXCPTRangePlot alloc] init];
	dataSourceLinePlot.identifier = @"Date Plot";
	
	// Add line style
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth             = 1.25;
	lineStyle.lineColor             = [CPTColor colorWithCGColor:self.plotColors.firstObject.CGColor];
	dataSourceLinePlot.barLineStyle = lineStyle;
	
	// Bar properties
	dataSourceLinePlot.barWidth   = 6.0;
	dataSourceLinePlot.gapWidth   = 0.0;
	dataSourceLinePlot.gapHeight  = 0.0;
	dataSourceLinePlot.dataSource = self;
	
	return @[dataSourceLinePlot];
}

- (void)mouseMoved:(NSEvent *)event
{
	
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Network Requests", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"networkActivity"];
}

- (CGFloat)requiredHeight
{
	return MAX(_requiredHeight * 2, super.requiredHeight);
}

- (NSArray<NSString *> *)plotTitles
{
	return @[NSLocalizedString(@"URL", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor colorWithRed:68.0/255.0 green:190.0/255.0 blue:30.0/255.0 alpha:1.0]];
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
	return _aggregates.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	_DTXNetworkSampleAggregate* aggregate = _aggregates[index];
	
	NSTimeInterval timestampt = [aggregate.timestamp timeIntervalSinceReferenceDate] - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval responseTimestampt = [aggregate.responseTimestamp ?: [NSDate distantFuture] timeIntervalSinceReferenceDate]  - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval range = responseTimestampt - timestampt;
	NSTimeInterval avg = (timestampt + responseTimestampt) / 2;
	
	switch (fieldEnum) {
		case CPTRangePlotFieldX:
			return @(avg);
		case CPTRangePlotFieldY:
			return @(aggregate.plotHeight);
		case CPTRangePlotFieldLeft:
		case CPTRangePlotFieldRight:
			return @(range / 2.0);
		default:
			return @0;
	}
}

-(nullable CPTLineStyle *)barLineStyleForRangePlot:(nonnull CPTRangePlot *)plot recordIndex:(NSUInteger)idx
{
	_DTXNetworkSampleAggregate* aggregate = _aggregates[idx];
	
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth = MIN(aggregate.lineWidth, 3.0);
	lineStyle.lineColor = [CPTColor colorWithCGColor:self.plotColors.firstObject.CGColor];
	lineStyle.lineCap = kCGLineCapButt;
	lineStyle.lineColor = [CPTColor colorWithCGColor:[_startColor interpolateToValue:_endColor progress:aggregate.lineWidth / _maxWidth].CGColor];
	
	return lineStyle;
}

@end
