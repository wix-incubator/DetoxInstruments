//
//  DTXActivityPlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXIntervalSamplePlotController.h"

extern NSString* const DTXActivityPlotEnabledCategoriesDidChange;

@interface DTXActivityPlotController : DTXIntervalSamplePlotController

#if ! PROFILER_PREVIEW_EXTENSION
- (NSSet<NSString*>*)enabledCategories;
#endif

@end
