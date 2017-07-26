//
//  DTXManagedPlotControllerGroup.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 02/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPlotController.h"

@class DTXManagedPlotControllerGroup;

@protocol DTXManagedPlotControllerGroupDelegate <NSObject>

- (void)managedPlotControllerGroup:(DTXManagedPlotControllerGroup*)group requestPlotControllerSelection:(id<DTXPlotController>)plotController;
- (void)managedPlotControllerGroup:(DTXManagedPlotControllerGroup *)group requiredHeightChangedForPlotController:(id<DTXPlotController>)plotController index:(NSUInteger)index;

@end

@interface DTXManagedPlotControllerGroup : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithHostingView:(NSView*)view;

@property (nonatomic, weak) id<DTXManagedPlotControllerGroupDelegate> delegate;

@property (nonatomic, strong) NSView* hostingView;
@property (nonatomic, copy, readonly) NSArray<id<DTXPlotController>>* plotControllers;
@property (nonatomic, copy, readonly) id<DTXPlotController> headerPlotController;

- (void)addHeaderPlotController:(id<DTXPlotController>)headerPlotController;
- (void)addPlotController:(id<DTXPlotController>)plotController;
- (void)insertPlotController:(id<DTXPlotController>)plotController afterPlotController:(id<DTXPlotController>)afterPlotController;
- (void)removePlotController:(id<DTXPlotController>)plotController;

- (void)setStartTimestamp:(NSDate*)startTimestamp endTimestamp:(NSDate*)endTimestamp;
- (void)zoomIn;
- (void)zoomOut;

@end
