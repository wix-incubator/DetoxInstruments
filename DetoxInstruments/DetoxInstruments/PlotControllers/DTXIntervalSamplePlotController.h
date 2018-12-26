//
//  DTXIntervalSamplePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/20/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSamplePlotController.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXIntervalSamplePlotController : DTXSamplePlotController

- (NSDate*)endTimestampForSample:(__kindof DTXSample*)sample;
- (NSColor*)colorForSample:(__kindof DTXSample*)sample;
- (NSString*)titleForSample:(__kindof DTXSample*)sample;
+ (Class)classForIntervalSamples;
- (NSArray<NSSortDescriptor*>*)sortDescriptors;

@end

NS_ASSUME_NONNULL_END
