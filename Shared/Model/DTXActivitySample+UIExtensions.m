//
//  DTXActivitySample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXActivitySample+UIExtensions.h"
#import "DTXEventStatusPrivate.h"
#if ! CLI
#import "NSColor+UIAdditions.h"
#endif
#import "DTXRecording+UIExtensions.h"
#import "DTXThreadInfo+UIExtensions.h"

@implementation DTXActivitySample (UIExtensions)

+ (BOOL)hasActivitySamplesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
	NSFetchRequest* fr = [self fetchRequest];
	return [managedObjectContext countForFetchRequest:fr error:NULL] > 0;
}

#if ! CLI
- (NSColor*)plotControllerColor
{
	return [NSColor randomColorWithSeed:self.category];
}
#endif

@end
