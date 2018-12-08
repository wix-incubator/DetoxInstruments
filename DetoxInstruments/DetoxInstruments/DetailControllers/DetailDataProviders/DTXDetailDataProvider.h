//
//  DTXDetailDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import Foundation;
@import AppKit;

#import "DTXRecordingDocument.h"
#import "NSFormatter+PlotFormatters.h"
#import "NSColor+UIAdditions.h"
#import "DTXInstrumentsModel.h"
#import "DTXInspectorDataProvider.h"
#import "DTXPlotController.h"
#import "DTXSampleContainerProxy.h"

@protocol DTXPlotController;

@interface DTXColumnInformation : NSObject

@property (nonatomic, copy) NSString* title;
@property (nonatomic) CGFloat minWidth;
@property (nonatomic, strong) NSSortDescriptor* sortDescriptor;

//Will only be considered for the last column.
@property (nonatomic) BOOL automaticallyGrowsWithTable;

@end

@protocol DTXUIDataFiltering

@property (nonatomic, assign, readonly) BOOL supportsDataFiltering;

- (void)filterSamplesWithFilter:(NSString*)filter;
- (NSPredicate*)predicateForFilter:(NSString*)filter;

@end

@protocol DTXDetailDataProvider;

@protocol DTXDetailDataProviderDelegate

- (void)dataProvider:(id<DTXDetailDataProvider>)provider didSelectInspectorItem:(DTXInspectorDataProvider*)item;

@end

@protocol DTXDetailDataProvider <DTXUIDataFiltering>

+ (Class)inspectorDataProviderClass;
- (Class)dataExporterClass;

@property (nonatomic, strong, readonly) DTXInspectorDataProvider* currentlySelectedInspectorItem;
@property (nonatomic, weak) id<DTXDetailDataProviderDelegate> delegate;

@end

@interface DTXDetailDataProvider : NSObject <DTXDetailDataProvider>

- (instancetype)initWithDocument:(DTXRecordingDocument*)document plotController:(id<DTXPlotController>)plotController;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) DTXRecordingDocument* document;
@property (nonatomic, weak, readonly) id<DTXPlotController> plotController;
@property (nonatomic, weak) NSOutlineView* managedOutlineView;

@property (nonatomic, strong, readonly) DTXSampleContainerProxy* rootGroupProxy;

@property (nonatomic, strong, readonly) NSString* displayName;
@property (nonatomic, strong, readonly) NSImage* displayIcon;

//@property (nonatomic, strong, readonly) NSArray<NSNumber* /*DTXSampleType*/>* sampleTypes;
@property (nonatomic, strong, readonly) Class sampleClass;
@property (nonatomic, strong, readonly) NSArray<NSString*>* filteredAttributes;
@property (nonatomic, readonly) BOOL showsHeaderView;
@property (nonatomic, strong, readonly) NSArray<DTXColumnInformation*>* columns;
@property (nonatomic, readonly) BOOL showsTimestampColumn;
@property (nonatomic, readonly) BOOL supportsSorting;

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
- (NSColor*)textColorForItem:(id)item;
- (NSColor*)backgroundRowColorForItem:(id)item;
- (NSString*)statusTooltipforItem:(id)item;
- (DTXSampleContainerProxy*)rootSampleContainerProxy;

- (void)selectSample:(DTXSample*)sample;

@end
