//
//  DTXDetailContentController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInstrumentsModel.h"
#import "DTXDetailDataProvider.h"
#import "DTXPlotController.h"

@class DTXDetailContentController;

@protocol DTXDetailContentControllerDelegate

- (void)bottomController:(DTXDetailContentController*)bc updateWithInspectorProvider:(DTXInspectorDataProvider*)inspectorProvider;

@end

@interface DTXDetailContentController : NSViewController

@property (nonatomic, strong) DTXRecordingDocument* document;
@property (nonatomic, weak) id<DTXDetailContentControllerDelegate> delegate;
@property (nonatomic, weak) id<DTXPlotController> managingPlotController;

@property (nonatomic, strong, readonly) DTXDetailController* activeDetailController;

@end
