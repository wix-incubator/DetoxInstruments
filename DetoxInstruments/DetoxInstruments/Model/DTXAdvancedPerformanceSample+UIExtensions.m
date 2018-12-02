//
//  DTXAdvancedPerformanceSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXAdvancedPerformanceSample+UIExtensions.h"
#import "DTXThreadPerformanceSample+CoreDataClass.h"
#import "DTXThreadInfo+UIExtensions.h"

@implementation DTXAdvancedPerformanceSample (UIExtensions)

- (NSString*)heaviestThreadName
{
	NSNumber* maxThreadCPU = [self valueForKeyPath:@"threadSamples.@max.cpuUsage"];
	return [self.threadSamples filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"cpuUsage == %@", maxThreadCPU]].firstObject.threadInfo.friendlyName;
}

@end
