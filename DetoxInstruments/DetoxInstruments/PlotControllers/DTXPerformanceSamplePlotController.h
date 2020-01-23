//
//  DTXPerformanceSamplePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXSamplePlotController.h"

@interface DTXPerformanceSamplePlotController : DTXSamplePlotController

+ (Class)classForPerformanceSamples;
- (NSPredicate*)predicateForPerformanceSamples;

+ (Class)classForPlotViews;

- (CGFloat)plotHeightMultiplier;
- (CGFloat)minimumValueForPlotHeight;

- (NSArray*)samplesForPlotIndex:(NSUInteger)index;
- (NSArray<NSString*>*)sampleKeys;
- (BOOL)isStepped;


@end
