//
//  DTXPlotControllerPickerCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/12/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXPlotController.h"

@interface DTXPlotControllerPickerCellView : NSTableCellView

@property (nonatomic, strong) id<DTXPlotController>plotController;
@property (nonatomic, getter=isPlotControllerEnabled) BOOL plotControllerEnabled;

@end
