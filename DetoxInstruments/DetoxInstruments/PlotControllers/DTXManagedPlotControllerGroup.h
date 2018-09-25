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

- (void)managedPlotControllerGroup:(DTXManagedPlotControllerGroup*)group didSelectPlotController:(id<DTXPlotController>)plotController;
- (void)managedPlotControllerGroup:(DTXManagedPlotControllerGroup*)group didHidePlotController:(id<DTXPlotController>)plotController;
- (void)managedPlotControllerGroup:(DTXManagedPlotControllerGroup*)group didShowPlotController:(id<DTXPlotController>)plotController;

@end

@interface DTXManagedPlotControllerGroup : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithHostingOutlineView:(NSOutlineView*)outlineView document:(DTXRecordingDocument*)document;

@property (nonatomic, weak) id<DTXManagedPlotControllerGroupDelegate> delegate;

@property (nonatomic, strong) id<DTXPlotController> headerPlotController;
@property (nonatomic, strong) id<DTXPlotController> touchBarPlotController;

//Main plot controllers
@property (nonatomic, readonly, copy) NSArray<id<DTXPlotController>>* plotControllers;
- (void)addPlotController:(id<DTXPlotController>)plotController;
- (void)removePlotController:(id<DTXPlotController>)plotController;

@property (nonatomic, readonly, copy) NSArray<id<DTXPlotController>>* visiblePlotControllers;
- (void)setPlotControllerHidden:(id<DTXPlotController>)plotController;
- (void)setPlotControllerVisible:(id<DTXPlotController>)plotController;
- (BOOL)isPlotControllerVisible:(id<DTXPlotController>)plotController;
- (void)resetPlotControllerVisibility;

//Child plot controllers
- (NSArray<id<DTXPlotController>>*)childPlotControllersForPlotController:(id<DTXPlotController>)plotController;
- (void)addChildPlotController:(id<DTXPlotController>)childPlotController toPlotController:(id<DTXPlotController>)plotController;
- (void)removeChildPlotController:(id<DTXPlotController>)childPlotController ofPlotController:(id<DTXPlotController>)plotController;

//Group plot range control
- (void)setLocalStartTimestamp:(NSDate*)startTimestamp endTimestamp:(NSDate*)endTimestamp;
- (void)setGlobalStartTimestamp:(NSDate*)startTimestamp endTimestamp:(NSDate*)endTimestamp;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomToFitAllData;

@end
