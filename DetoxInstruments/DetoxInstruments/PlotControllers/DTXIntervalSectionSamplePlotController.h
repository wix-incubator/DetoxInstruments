//
//  DTXIntervalSectionSamplePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 2/6/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRangePlotView.h"
#import "DTXFilteredDataProvider.h"
#import "DTXIntervalSamplePlotController.h"

@interface DTXIntervalSectionSamplePlotController : NSObject

@property (nonatomic, strong) DTXRangePlotView* plotView;
@property (nonatomic, weak) DTXFilteredDataProvider* filteredDataProvider;
@property (nonatomic, readonly) BOOL isForTouchBar;
@property (nonatomic, weak) DTXIntervalSamplePlotController* intervalSamplePlotController;
@property (nonatomic) NSUInteger section;

- (instancetype)initWithIntervalSamplePlotController:(DTXIntervalSamplePlotController*)intervalSamplePlotController fetchedResultsController:(NSFetchedResultsController*)frc isForTouchBar:(BOOL)isForTouchBar;

- (void)reloadData;

- (void)highlightSample:(DTXSample*)sample;
- (void)removeHighlight;
- (id)sampleAtRangeIndex:(NSUInteger)idx;

- (void)resetAfterFilter;

@end

