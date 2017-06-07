//
//  DTXManagedPlotControllerGroup.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 02/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPlotController.h"

@interface DTXManagedPlotControllerGroup : NSObject

- (instancetype)initWithHostingView:(NSView*)view NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSView* hostingView;
@property (nonatomic, copy, readonly) NSArray<id<DTXPlotController>>* plotControllers;
@property (nonatomic, copy, readonly) id<DTXPlotController> headerPlotController;

- (void)addHeaderPlotController:(id<DTXPlotController>)headerPlotController;
- (void)addPlotController:(id<DTXPlotController>)plotController;

@end
