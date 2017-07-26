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

- (NSFetchRequest<DTXSample*>*)fetchRequestForSamplesWithTypes:(NSArray<NSNumber*>*)sampleTypes includingGroups:(BOOL)includeGroups;

@end
