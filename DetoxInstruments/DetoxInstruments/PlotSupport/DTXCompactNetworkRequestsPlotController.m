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

@interface DTXCompactNetworkRequestsPlotController ()
{
	NSMutableArray<NSMutableArray<DTXNetworkSample*>*>* _mergedSamples;
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

- (NSArray<NSArray*>*)samplesForPlots
{
	NSMutableArray* rv = [NSMutableArray new];
	NSMutableArray* resultIndexPaths = [NSMutableArray new];
	
	if(_mergedSamples == nil)
	{
		_mergedSamples = [NSMutableArray new];
	}
	
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sampleKey, NSUInteger idx, BOOL * _Nonnull stop) {
		NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		
		NSArray<DTXNetworkSample*>* results = [self.document.recording.managedObjectContext executeFetchRequest:fr error:NULL];
		
		if(results == nil)
		{
			*stop = YES;
			return;
		}
		
		[results enumerateObjectsUsingBlock:^(DTXNetworkSample * _Nonnull currentSample, NSUInteger idx, BOOL * _Nonnull stop) {
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
			[resultIndexPaths addObject:@{@"ip": indexPath}];
		}];
	}];
	
	[rv addObject:resultIndexPaths];
	
	return rv;
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
	return MAX(_mergedSamples.count * 2 * 4 + 6, super.requiredHeight);
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"totalDataLength"];
}

- (NSArray<NSString *> *)plotTitles
{
	return @[NSLocalizedString(@"URL", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor colorWithRed:68.0/255.0 green:190.0/255.0 blue:30.0/255.0 alpha:1.0]];
}

- (NSFormatter*)formatterForDataPresentation
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
	return self.samples.firstObject.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSIndexPath* indexPath = self.samples.firstObject[index][@"ip"];
	
	DTXNetworkSample* sample = _mergedSamples[indexPath.section][indexPath.item];
	
	NSTimeInterval timestampt = [sample.timestamp timeIntervalSinceReferenceDate] - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval responseTimestampt = [sample.responseTimestamp ?: [NSDate distantFuture] timeIntervalSinceReferenceDate]  - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval range = responseTimestampt - timestampt;
	NSTimeInterval avg = (timestampt + responseTimestampt) / 2;
	
	switch (fieldEnum) {
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

@end

