//
//  DTXInstrumentsWindowController+DocumentationGeneration.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#ifdef DEBUG

#import "DTXInstrumentsWindowController.h"

@interface DTXInstrumentsWindowController (DocumentationGeneration)

- (void)_drainLayout;
- (void)_setWindowSizeToScreenPercentage:(CGPoint)percentage;
- (void)_deselectAllPlotControllers;
- (void)_selectPlotControllerOfClass:(Class)cls;
- (NSImage*)_snapshotForPlotControllerOfClass:(Class)cls;
- (void)_setBottomSplitAtPercentage:(CGFloat)percentage;
- (void)_deselectAnyDetail;
- (NSImage*)_snapshotForDetailPane;
- (void)_scrollBottomPaneToPercentage:(CGFloat)percentage;
- (void)_selectSampleAtIndex:(NSInteger)index forPlotControllerClass:(Class)cls;
- (NSImage*)_snapshotForInspectorPane;

@end

#endif
