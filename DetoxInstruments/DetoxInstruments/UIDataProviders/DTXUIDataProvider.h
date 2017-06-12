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
#import "DTXInstrumentsModel.h"
#import "DTXDocument.h"
#import "DTXUISampleTypes.h"

@class DTXUIDataProvider;

@interface DTXUIDataProvider : NSObject

@property (nonatomic, strong, readonly) DTXDocument* document;

@property (nonatomic, weak) NSOutlineView* managedOutlineView;

- (instancetype)initWithDocument:(DTXDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (DTXSampleType)sampleType;

- (NSArray<NSString*>*)columnTitles;
- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;


@end
