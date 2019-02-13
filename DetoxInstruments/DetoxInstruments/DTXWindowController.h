//
//  DTXWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXPlotController.h"

@protocol DTXWindowWideCopyHanler <NSObject>

@required
- (BOOL)canCopy;
- (void)copy:(id)sender targetView:(__kindof NSView*)targetView;

@end

@interface DTXWindowController : NSWindowController

@property (nonatomic, strong, readonly) id<DTXPlotController> currentPlotController;

@property (nonatomic, weak, readonly) NSSegmentedControl* layoutSegmentControl;

@property (nonatomic, weak) __kindof NSView* targetForCopy;
@property (nonatomic, weak) id<DTXWindowWideCopyHanler> handlerForCopy;

- (void)reloadTouchBar;

@end
