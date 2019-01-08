//
//  DTXStackedPlotGroup.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 05/08/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <CorePlot/CorePlot.h>

@interface CPTPlotGroup : CPTLayer
@end

@interface DTXStackedPlotGroup : CPTPlotGroup

@property (nonatomic, readonly) BOOL isForTouchBar;

- (instancetype)initForTouchBar:(BOOL)isForTouchBar;

@end
