//
//  DTXPlotController-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/3/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXPlotController.h"

@protocol DTXPlotControllerPrivate <DTXPlotController>

- (void)_removeHighlightNotifyingDelegate:(BOOL)notify;

@end
