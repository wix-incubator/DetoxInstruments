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

- (NSDate*)endTimestampForSample:(DTXSample*)sample;
- (NSColor*)colorForSample:(DTXSample*)sample;
+ (Class)classForIntervalSamples;
- (NSArray<NSSortDescriptor*>*)sortDescriptors;

@end

NS_ASSUME_NONNULL_END
