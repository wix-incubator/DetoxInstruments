//
//  DTXIntervalSamplePlotController-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 2/13/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXIntervalSamplePlotController.h"

@interface DTXSamplePlotController ()

- (instancetype)_initWithDocument:(DTXRecordingDocument*)document isForTouchBar:(BOOL)isForTouchBar sectionConfigurator:(void(^)(void))configurator;

@end
