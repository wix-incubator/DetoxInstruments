//
//  DTXSignpostSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostSample+UIExtensions.h"
#import "DTXEventStatus.h"

@implementation DTXSignpostSample (UIExtensions)

+ (BOOL)hasSignpostSamplesForManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
	NSFetchRequest* fr = [self fetchRequest];
	return [managedObjectContext countForFetchRequest:fr error:NULL] > 0;
}

- (NSUInteger)count
{
	return 1;
}

- (NSTimeInterval)minDuration
{
	return self.duration;
}

- (NSTimeInterval)avgDuration
{
	return self.duration;
}

- (NSTimeInterval)maxDuration
{
	return self.duration;
}

- (NSTimeInterval)stddevDuration
{
	return self.duration;
}

- (NSString *)eventStatusString
{
	if(self.eventStatus == DTXEventStatusError)
	{
		return NSLocalizedString(@"Error", @"");
	}
	
	NSMutableString* completed = [NSLocalizedString(@"Completed", @"") mutableCopy];
	if(self.eventStatus > DTXEventStatusError)
	{
		[completed appendString:[NSString stringWithFormat:@" (Category %@)", @(self.eventStatus - DTXEventStatusError)]];
	}
	
	return completed;
}

- (BOOL)isGroup
{
	return NO;
}

@end
