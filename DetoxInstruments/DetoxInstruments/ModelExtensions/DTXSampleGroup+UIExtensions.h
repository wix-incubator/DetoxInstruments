//
//  DTXSampleGroup+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInstrumentsModel.h"
#import "DTXSampleGroup+CoreDataClass.h"

@interface DTXSampleGroup (UIExtensions)

- (NSArray<DTXSample *>*)samplesWithTypes:(NSArray<NSNumber* /* DTXSampleType */>*)sampleTypes includingGroups:(BOOL)includeGroups;

@end
