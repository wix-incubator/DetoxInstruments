//
//  DTXWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXPlotController.h"

@interface DTXWindowController : NSWindowController

@property (nonatomic, strong, readonly) id<DTXPlotController> currentPlotController;

@property (nonatomic, weak, readonly) NSSegmentedControl* layoutSegmentControl;

- (void)reloadTouchBar;

@end
