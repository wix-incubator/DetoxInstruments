//
//  DTXWindowController+DocumentationGeneration.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#ifdef DEBUG

#import "DTXWindowController.h"
#import "DTXProfilingTargetManagementWindowController.h"
#import "DTXLiveLogWindowController.h"
#import "DTXRequestsPlaygroundWindowController.h"
#import "NSWindowController+DocumentationGeneration.h"

@interface DTXWindowController (DocumentationGeneration)

- (void)_deselectAnyPlotControllers;
- (void)_selectPlotControllerOfClass:(Class)cls;
- (NSImage*)_snapshotForPlotControllerOfClass:(Class)cls;
- (NSImage*)_snapshotForOnlyPlotOfPlotControllerOfClass:(Class)cls;
- (NSImage*)_snapshotForTimeline;
- (void)_setBottomSplitAtPercentage:(CGFloat)percentage;
- (void)_deselectAnyDetail;
- (NSImage*)_snapshotForDetailPane;
- (void)_scrollBottomPaneToPercentage:(CGFloat)percentage;
- (void)_selectSampleAtIndex:(NSInteger)index forPlotControllerClass:(Class)cls;
- (void)_selectDetailControllerSampleAtIndex:(NSInteger)index;
- (void)_followOutlineBreadcrumbs:(NSArray*)breadcrumbs forPlotControllerClass:(Class)cls selectLastBreadcrumb:(BOOL)selectLastBreadcrumb;
- (NSImage*)_snapshotForInspectorPane;
- (void)_selectDetailPaneIndex:(NSUInteger)idx;

- (NSImage*)_snapshotForTargetSelection;

- (void)_dismissTargetSelection;

- (NSImage*)_snapshotForInstrumentsCustomization;

- (void)_triggerDetailMenu;

- (void)_removeDetailVerticalScroller;

- (void)_setRecordingButtonsVisible:(BOOL)recordingButtonsVisible;

- (void)_selectExtendedDetailInspector;
- (void)_selectProfilingInfoInspector;

- (DTXLiveLogWindowController*)_openLiveConsoleWindowController;
- (DTXProfilingTargetManagementWindowController*)_openManagementWindowController;

- (NSSize)_plotDetailsSplitViewControllerSize;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)fitAllData:(id)sender;

@end

#endif
