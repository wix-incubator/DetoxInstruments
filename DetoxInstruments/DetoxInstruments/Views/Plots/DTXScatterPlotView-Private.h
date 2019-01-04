//
//  DTXScatterPlotView-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/31/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotView-Private.h"
#import "DTXScatterPlotView.h"

@protocol DTXPlotHeightSynchronization <NSObject>

@property (nonatomic) double maximumPlotHeight;

@end

@interface DTXScatterPlotView ()

@property (nonatomic) double maxHeight;
@property (nonatomic, weak) id<DTXPlotHeightSynchronization> heightSynchronizer;

@end
