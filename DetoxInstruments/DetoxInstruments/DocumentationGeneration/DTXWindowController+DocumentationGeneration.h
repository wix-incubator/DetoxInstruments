//
//  DTXWindowController+DocumentationGeneration.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#ifdef DEBUG

#import "DTXWindowController.h"
#import "DTXProfilingTargetManagementWindowController.h"

@interface DTXWindowController (DocumentationGeneration)

- (void)_drainLayout;
- (void)_setWindowSize:(NSSize)size;
- (void)_deselectAnyPlotControllers;
- (void)_selectPlotControllerOfClass:(Class)cls;
- (NSImage*)_snapshotForPlotControllerOfClass:(Class)cls;
- (NSImage*)_snapshotForTimeline;
- (void)_setBottomSplitAtPercentage:(CGFloat)percentage;
- (void)_deselectAnyDetail;
- (NSImage*)_snapshotForDetailPane;
- (void)_scrollBottomPaneToPercentage:(CGFloat)percentage;
- (void)_selectSampleAtIndex:(NSInteger)index forPlotControllerClass:(Class)cls;
- (NSImage*)_snapshotForInspectorPane;

- (NSImage*)_snapshotForTargetSelection;
- (NSImage*)_snapshotForRecordingSettings;

- (void)_triggerDetailMenu;

- (void)_removeDetailVerticalScroller;

- (void)_setRecordingButtonsVisible:(BOOL)recordingButtonsVisible;

- (void)_selectExtendedDetailInspector;
- (void)_selectProfilingInfoInspector;

- (DTXProfilingTargetManagementWindowController*)_openManagementWindowController;

@end

#endif
