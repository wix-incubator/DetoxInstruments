//
//  DTXNetworkSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXNetworkSample+UIExtensions.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXRecording+UIExtensions.h"

extern NSByteCountFormatter* __byteFormatter;

@implementation DTXNetworkSample (UIExtensions)

+ (BOOL)hasNetworkSamplesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
	NSFetchRequest* fr = [self fetchRequest];
	return [managedObjectContext countForFetchRequest:fr error:NULL] > 0;
}

@end
