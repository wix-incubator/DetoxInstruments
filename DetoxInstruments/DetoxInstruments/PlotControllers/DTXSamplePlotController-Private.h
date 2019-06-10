//
//  DTXSamplePlotController-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/3/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSamplePlotController.h"
#import "DTXPlotController-Private.h"

@interface DTXSamplePlotController () <DTXPlotControllerPrivate>

- (NSColor*)_plotColorForIdx:(NSUInteger)idx;
- (NSColor*)_additionalPlotColorForIdx:(NSUInteger)idx;

- (void)_highlightSample:(DTXSample*)sample sampleIndex:(NSUInteger)sampleIdx plotIndex:(NSUInteger)plotIndex positionInPlot:(double)position valueAtClickPosition:(double)value;

@end
