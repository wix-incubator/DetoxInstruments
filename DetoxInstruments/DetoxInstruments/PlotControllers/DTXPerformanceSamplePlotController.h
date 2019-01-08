//
//  DTXPerformanceSamplePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSamplePlotController.h"

@interface DTXPerformanceSamplePlotController : DTXSamplePlotController

+ (Class)classForPerformanceSamples;
- (NSPredicate*)predicateForPerformanceSamples;

- (CGFloat)plotHeightMultiplier;
- (CGFloat)minimumValueForPlotHeight;

@end
