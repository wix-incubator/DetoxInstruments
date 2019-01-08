//
//  DTXAdvancedPerformanceSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXAdvancedPerformanceSample+UIExtensions.h"
#import "DTXThreadPerformanceSample+CoreDataClass.h"
#import "DTXThreadInfo+UIExtensions.h"

@implementation DTXAdvancedPerformanceSample (UIExtensions)

- (NSString*)heaviestThreadName
{
	if(self.heaviestThreadIdx == nil)
	{
		//Legacy for old recordings.
		NSNumber* maxThreadCPU = [self valueForKeyPath:@"threadSamples.@max.cpuUsage"];
		return [self.threadSamples filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"cpuUsage == %@", maxThreadCPU]].firstObject.threadInfo.friendlyName;
	}
	
	NSInteger idx = self.heaviestThreadIdx.integerValue;
	if(idx == -1)
	{
		return nil;
	}
	
	return self.threadSamples[idx].threadInfo.friendlyName;
}

@end
