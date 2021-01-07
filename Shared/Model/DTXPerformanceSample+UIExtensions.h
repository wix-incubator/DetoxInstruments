//
//  DTXPerformanceSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXPerformanceSample+CoreDataClass.h"
@import CoreData;

@interface DTXPerformanceSample (UIExtensions)

@property (nonatomic, copy, readonly) NSArray<NSString*>* dtx_sanitizedOpenFiles;
- (NSString*)heaviestThreadName;

@end
