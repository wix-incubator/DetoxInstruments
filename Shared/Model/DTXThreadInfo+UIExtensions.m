//
//  DTXThreadInfo+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXThreadInfo+UIExtensions.h"
#import "NSObject+AttachedObjects.h"

static void* THREAD_MAPPING = &THREAD_MAPPING;

@implementation DTXThreadInfo (UIExtensions)

+ (NSString *)mainThreadFriendlyName
{
	return NSLocalizedString(@"Main Thread", @"");
}

+ (DTXThreadInfo*)threadInfoForThreadNumber:(int64_t)threadNumber inManagedObjectContext:(NSManagedObjectContext*)ctx
{
	NSMutableDictionary* mapping = [ctx dtx_attachedObjectForKey:THREAD_MAPPING];
	if(mapping == nil)
	{
		mapping = [NSMutableDictionary new];
		[ctx dtx_attachObject:mapping forKey:THREAD_MAPPING];
	}
	
	DTXThreadInfo* rv = mapping[@(threadNumber)];
	if(rv == nil)
	{
		NSFetchRequest* fr = self.fetchRequest;
		fr.predicate = [NSPredicate predicateWithFormat:@"number == %ld", threadNumber];
		rv = [ctx executeFetchRequest:fr error:NULL].firstObject;
		mapping[@(threadNumber)] = rv;
	}
	
	return rv;
}

- (NSString*)friendlyName
{
	if(self.number == 0)
	{
		return DTXThreadInfo.mainThreadFriendlyName;
	}
	
	return [NSString stringWithFormat:@"%@%@%@", self.name.length == 0 ? NSLocalizedString(@"Thread ", @"") : @"", @(self.number + 1), self.name.length > 0 ? [NSString stringWithFormat:@" (%@)", self.name] : @""];
}

@end
