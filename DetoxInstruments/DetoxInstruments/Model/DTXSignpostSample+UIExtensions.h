//
//  DTXSignpostSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostSample+CoreDataClass.h"
@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface DTXSignpostSample (UIExtensions)

+ (BOOL)hasSignpostSamplesForManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end

NS_ASSUME_NONNULL_END
