//
//  DTXUIDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import Foundation;
@import AppKit;

#import "DTXDocument.h"
#import "NSFormatter+PlotFormatters.h"
#import "NSColor+UIAdditions.h"
#import "DTXInstrumentsModel.h"
#import "DTXUISampleTypes.h"
#import "DTXInspectorDataProvider.h"

@protocol DTXPlotController;

@interface DTXColumnInformation : NSObject

@property (nonatomic, copy) NSString* title;
@property (nonatomic) CGFloat minWidth;

//Will only be considered for the last column.
@property (nonatomic) BOOL automaticallyGrowsWithTable;

@end

@protocol DTXUIDataFiltering

@property (nonatomic, assign, readonly) BOOL supportsDataFiltering;

- (void)filterSamplesWithFilter:(NSString*)filter;

@end

@protocol DTXUIDataProvider;

@protocol DTXUIDataProviderDelegate

- (void)dataProvider:(id<DTXUIDataProvider>)provider didSelectInspectorItem:(DTXInspectorDataProvider*)item;

@end

@protocol DTXUIDataProvider <DTXUIDataFiltering>

@property (nonatomic, strong, readonly) DTXInspectorDataProvider* currentlySelectedInspectorItem;
@property (nonatomic, weak) id<DTXUIDataProviderDelegate> delegate;

@end

@interface DTXUIDataProvider : NSObject <DTXUIDataProvider>

+ (Class)inspectorDataProviderClass;

- (instancetype)initWithDocument:(DTXDocument*)document plotController:(id<DTXPlotController>)plotController;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) DTXDocument* document;
@property (nonatomic, weak, readonly) id<DTXPlotController> plotController;
@property (nonatomic, weak) NSOutlineView* managedOutlineView;

@property (nonatomic, strong, readonly) NSString* displayName;
@property (nonatomic, strong, readonly) NSImage* displayIcon;

@property (nonatomic, strong, readonly) NSArray<NSNumber* /*DTXSampleType*/>* sampleTypes;
@property (nonatomic, strong, readonly) NSArray<NSString*>* filteredAttributes;
@property (nonatomic, readonly) BOOL showsHeaderView;
@property (nonatomic, strong, readonly) NSArray<DTXColumnInformation*>* columns;

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
- (NSColor*)textColorForItem:(id)item;
- (NSColor*)backgroundRowColorForItem:(id)item;

- (void)selectSample:(DTXSample*)sample;

@end
