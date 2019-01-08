//
//  DTXPerformanceSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPerformanceSample+CoreDataClass.h"

@interface DTXPerformanceSample (UIExtensions)

@property (nonatomic, copy, readonly) NSArray<NSString*>* dtx_sanitizedOpenFiles;

@end
