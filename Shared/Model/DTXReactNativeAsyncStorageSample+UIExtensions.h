//
//  DTXReactNativeAsyncStorageSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/22/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXReactNativeAsyncStorageSample+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXReactNativeAsyncStorageSample (UIExtensions)

+ (BOOL)hasAsyncStorageSamplesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end

NS_ASSUME_NONNULL_END
