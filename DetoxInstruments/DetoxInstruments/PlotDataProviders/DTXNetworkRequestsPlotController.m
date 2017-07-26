//
//  DTXNetworkRequestsPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXNetworkRequestsPlotController.h"
#import <CorePlot/CorePlot.h>
#import "DTXNetworkSample+CoreDataClass.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXGraphHostingView.h"
#import "DTXNetworkDataProvider.h"
#import "DTXCPTRangePlot.h"

//extern NSColor* __DTXDarkerColorFromColor(NSColor* color);
//extern NSColor* __DTXLighterColorFromColor(NSColor* color);

@interface DTXNetworkRequestsPlotController ()
@end

@implementation DTXNetworkRequestsPlotController

+ (Class)graphHostingViewClass
{
	return [DTXInvertedGraphHostingView class];
}

+ (Class)UIDataProviderClass
{
	return [DTXNetworkDataProvider class];
}

- (NSArray<NSArray *> *)samplesForPlots
{
	NSMutableArray* rv = [NSMutableArray new];
	
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sampleKey, NSUInteger idx, BOOL * _Nonnull stop) {
		NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		
		NSArray* results = [self.document.recording.managedObjectContext executeFetchRequest:fr error:NULL];
		
		if(results == nil)
		{
			*stop = YES;
			return;
		}
		
		[rv addObject:results];
	}];
	
	if(rv.count != self.sampleKeys.count)
	{
		return nil;
	}
	
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

- (void)highlightSample:(id)sample
{
	
}

- (void)highlightRange:(CPTPlotRange *)range
{
	
}

- (void)removeHighlight
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
	return MAX(self.samples.firstObject.count * 2 * 3 + 6, super.requiredHeight);
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
	return 1.0;
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
	NSTimeInterval timestampt = [[(DTXNetworkSample*)self.samples.firstObject[index] timestamp] timeIntervalSinceReferenceDate] - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval responseTimestampt = [[(DTXNetworkSample*)self.samples.firstObject[index] responseTimestamp] ?: [NSDate distantFuture] timeIntervalSinceReferenceDate]  - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	NSTimeInterval range = responseTimestampt - timestampt;
	NSTimeInterval avg = (timestampt + responseTimestampt) / 2;
	
	switch (fieldEnum) {
		case CPTRangePlotFieldX:
			return @(avg);
		case CPTRangePlotFieldY:
			return @(index);
		case CPTRangePlotFieldLeft:
		case CPTRangePlotFieldRight:
			return @(range / 2.0);
		default:
			return @0;
	}
}

@end
