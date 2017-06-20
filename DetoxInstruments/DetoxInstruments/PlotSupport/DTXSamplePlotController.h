//
//  DTXSamplePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CorePlot/CorePlot.h>
#import "DTXDocument.h"
#import "DTXPlotController.h"

@interface DTXSamplePlotController : NSObject <DTXPlotController, CPTScatterPlotDataSource, CPTBarPlotDataSource, CPTPlotSpaceDelegate>

@property (nonatomic, strong, readonly) NSArray<NSArray*>* samples;

+ (Class)graphHostingViewClass;
+ (Class)UIDataProviderClass;

- (NSArray<NSArray*>*)samplesForPlots;
- (NSArray<CPTPlot*>*)plots;
- (NSArray<CPTPlotSpaceAnnotation*>*)graphAnnotationsForGraph:(CPTGraph*)graph;
- (NSArray<NSString*>*)sampleKeys;
- (NSArray<NSColor*>*)plotColors;
- (NSArray<NSString*>*)plotTitles;
- (BOOL)isStepped;
- (NSEdgeInsets)rangeInsets;
- (CGFloat)yRangeMultiplier;

- (NSFormatter*)formatterForDataPresentation;
- (id)transformedValueForFormatter:(id)value;

@end
