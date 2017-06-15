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
#import "DTXDocument.h"
#import "DTXUISampleTypes.h"

@interface DTXColumnInformation : NSObject

@property (nonatomic, copy) NSString* title;
@property (nonatomic) CGFloat minWidth;

//Will only be considered for the last column.
@property (nonatomic) BOOL automaticallyGrowsWithTable;

@end

@interface DTXUIDataProvider : NSObject

@property (nonatomic, strong, readonly) DTXDocument* document;

@property (nonatomic, weak) NSOutlineView* managedOutlineView;

- (instancetype)initWithDocument:(DTXDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (DTXSampleType)sampleType;

- (NSArray<DTXColumnInformation*>*)columns;
- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
- (NSColor*)textColorForItem:(id)item;
- (NSColor*)backgroundRowColorForItem:(id)item;

@end
