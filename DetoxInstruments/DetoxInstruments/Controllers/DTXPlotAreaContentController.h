//
//  DTXPlotAreaContentController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXPlotController.h"
#import "DTXDetailDataProvider.h"

@class DTXPlotAreaContentController;

@protocol DTXPlotAreaContentControllerDelegate

- (void)reloadTouchBar;
- (void)contentController:(DTXPlotAreaContentController*)cc updatePlotController:(id<DTXPlotController>)plotController;
- (void)contentControllerDidDisableNowFollowing:(DTXPlotAreaContentController*)cc;

@end

@interface DTXPlotAreaContentController : NSViewController

- (void)zoomIn;
- (void)zoomOut;
- (void)fitAllData;

- (void)presentPlotControllerPickerFromView:(NSView*)view;

@property (nonatomic) BOOL nowModeEnabled;

@property (nonatomic, strong) DTXRecordingDocument* document;
@property (nonatomic, weak) id<DTXPlotAreaContentControllerDelegate> delegate;

@end
