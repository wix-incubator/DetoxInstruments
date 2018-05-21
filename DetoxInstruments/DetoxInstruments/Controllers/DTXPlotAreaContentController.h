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

- (void)contentController:(DTXPlotAreaContentController*)cc updatePlotController:(id<DTXPlotController>)plotController;

@end

@interface DTXPlotAreaContentController : NSViewController

- (void)zoomIn;
- (void)zoomOut;
- (void)fitAllData;

@property (nonatomic, strong) DTXDocument* document;
@property (nonatomic, weak) id<DTXPlotAreaContentControllerDelegate> delegate;

@end
