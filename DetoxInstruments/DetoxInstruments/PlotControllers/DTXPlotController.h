//
//  DTXPlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

@import Cocoa;
#import "DTXPlotRange.h"
#import "DTXRecordingDocument.h"

extern NSString* const DTXPlotControllerRequiredHeightDidChangeNotification;

@class DTXDetailController, DTXFilteredDataProvider;

@protocol DTXPlotController;

@protocol DTXPlotControllerDelegate <NSObject>

- (void)plotController:(id<DTXPlotController>)pc didChangeToPlotRange:(DTXPlotRange *)plotRange;
- (void)plotControllerUserDidClickInPlotBounds:(id<DTXPlotController>)pc;
- (void)plotController:(id<DTXPlotController>)pc didHighlightRange:(DTXPlotRange*)highlightRange;
- (void)plotControllerDidRemoveHighlight:(id<DTXPlotController>)pc;

@end

@protocol DTXPlotControllerSampleClickHandlingDelegate <NSObject>

- (void)plotController:(id<DTXPlotController>)pc didClickOnSample:(DTXSample *)sample;

@end

@protocol DTXPlotController <NSObject>

@property (nonatomic, strong, readonly) DTXRecordingDocument* document;
@property (nonatomic, weak) id<DTXPlotControllerDelegate> delegate;

@property (nonatomic, strong, readonly) NSString* displayName;
@property (nonatomic, strong, readonly) NSImage* displayIcon;
@property (nonatomic, strong, readonly) NSImage* smallDisplayIcon;
@property (nonatomic, strong, readonly) NSImage* secondaryIcon;
@property (nonatomic, strong, readonly) NSString* toolTip;
@property (nonatomic, strong, readonly) NSFont* titleFont;
@property (nonatomic, strong, readonly) NSArray<NSString*>* legendTitles;
@property (nonatomic, strong, readonly) NSArray<NSColor*>* legendColors;
@property (nonatomic, strong, readonly) NSString* helpTopicName;

@property (nonatomic, assign, readonly) CGFloat requiredHeight;

#if ! PROFILER_PREVIEW_EXTENSION
@property (nonatomic, copy, readonly) NSArray<DTXDetailController*>* dataProviderControllers;
#endif

- (instancetype)initWithDocument:(DTXRecordingDocument*)document isForTouchBar:(BOOL)isForTouchBar;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)setUpWithView:(NSView*)view;
- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets;

- (void)setGlobalPlotRange:(DTXPlotRange*)globalPlotRange;
- (void)setPlotRange:(DTXPlotRange*)plotRange;
- (void)setDataLimitRange:(DTXPlotRange*)plotRange;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomToFitAllData;

@optional

@property (nonatomic, weak) id<DTXPlotController> parentPlotController;
@property (nonatomic, weak) id<DTXPlotControllerSampleClickHandlingDelegate> sampleClickDelegate;

- (void)highlightSample:(id)sample;
- (void)shadowHighlightRange:(DTXPlotRange*)range;
- (void)removeHighlight;

@property (nonatomic, assign, readonly) BOOL canReceiveFocus;

@property (nonatomic, weak) DTXFilteredDataProvider* filteredDataProvider;

- (BOOL)supportsQuickSettings;
@property (nonatomic, strong, readonly) NSMenu* quickSettingsMenu;
- (IBAction)showQuickSettings:(id)sender;

@end
