//
//  DTXSamplePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPlotHostConstructor.h"
#import <CorePlot/CorePlot.h>
#import "DTXRecordingDocument.h"
#import "DTXPlotController.h"
#import "DTXPlotView.h"

@interface DTXSamplePlotController : DTXPlotHostConstructor <DTXPlotViewDelegate, DTXPlotController>

@property (nonatomic, strong, readonly) NSStoryboard* scene;

+ (Class)UIDataProviderClass;

- (void)prepareSamples;

- (NSArray<__kindof DTXPlotView*>*)plotViews;
- (BOOL)includeSeparatorsInStackView;

- (NSArray<NSString*>*)propertiesToFetch;
- (NSArray<NSString*>*)relationshipsToFetch;
- (NSArray<NSColor*>*)plotColors;
- (NSArray<NSColor*>*)additionalPlotColors;
- (NSArray<NSString*>*)plotTitles;
- (NSEdgeInsets)rangeInsets;

+ (NSFormatter*)formatterForDataPresentation;
+ (NSFormatter*)additionalFormatterForDataPresentation;
- (id)transformedValueForFormatter:(id)value;

- (void)updateLayerHandler;

@end
