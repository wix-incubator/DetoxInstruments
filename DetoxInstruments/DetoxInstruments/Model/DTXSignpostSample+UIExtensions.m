//
//  DTXSignpostSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostSample+UIExtensions.h"
#import "DTXEventStatusPrivate.h"
#import "NSColor+UIAdditions.h"
#import "DTXRecording+UIExtensions.h"

@implementation DTXSignpostSample (UIExtensions)

+ (BOOL)hasSignpostSamplesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
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

- (NSString*)eventTypeString
{
	return self.isEvent ? NSLocalizedString(@"Event", @"") : NSLocalizedString(@"Interval", @"");
}

- (NSString *)eventStatusString
{
	if(self.isEvent == NO && self.endTimestamp == nil)
	{
		return NSLocalizedString(@"Pending", @"");
	}
	
	switch (self.eventStatus) {
		case DTXEventStatusPrivateCancelled:
			return NSLocalizedString(@"Cancelled", @"");
		case DTXEventStatusPrivateError:
			return NSLocalizedString(@"Error", @"");
		default:
			return NSLocalizedString(@"Completed", @"");
	}
}

- (BOOL)isGroup
{
	return NO;
}

- (NSColor*)plotControllerColor
{
	DTXColorEffect effect = DTXColorEffectNormal;
	if(self.eventStatus == DTXEventStatusPrivateError)
	{
		effect = DTXColorEffectError;
	}
	else if(self.eventStatus == DTXEventStatusPrivateCancelled)
	{
		effect = DTXColorEffectCancelled;
	}
	else if(self.endTimestamp == nil && self.isEvent == NO)
	{
		effect = DTXColorEffectPending;
	}
	
	return [NSColor uiColorWithSeed:self.category effect:effect];
}

@end
