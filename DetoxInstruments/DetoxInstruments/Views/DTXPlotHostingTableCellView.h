//
//  DTXPlotHostingTableCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXPlotController.h"

@interface DTXPlotHostingTableCellView : NSTableCellView

@property (nonatomic, weak) id<DTXPlotController> plotController;

@end
