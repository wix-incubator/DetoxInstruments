//
//  DTXSamplePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXDocument.h"
#import "DTXPlotController.h"

@interface DTXSamplePlotController : NSObject <DTXPlotController>

- (instancetype)initWithDocument:(DTXDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) DTXDocument* document;

- (NSArray<NSArray<NSDictionary<NSString*, id>*>*>*)samplesForPlots;
- (NSArray<NSString*>*)sampleKeys;
- (NSArray<NSColor*>*)plotColors;
- (NSArray<NSString*>*)plotTitles;
- (BOOL)isStepped;

- (NSFormatter*)formatterForDataPresentation;
- (id)transformedValueForFormatter:(id)value;

@end
