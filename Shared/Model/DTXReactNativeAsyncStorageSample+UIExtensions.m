//
//  DTXReactNativeAsyncStorageSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/22/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXReactNativeAsyncStorageSample+UIExtensions.h"

@implementation DTXReactNativeAsyncStorageSample (UIExtensions)

+ (BOOL)hasAsyncStorageSamplesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
	NSFetchRequest* fr = [self fetchRequest];
	return [managedObjectContext countForFetchRequest:fr error:NULL] > 0;
}

@end
