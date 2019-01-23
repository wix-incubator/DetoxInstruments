//
//  DTXPerformanceSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPerformanceSample+UIExtensions.h"
#import "DTXThreadPerformanceSample+CoreDataClass.h"
#import "DTXThreadInfo+UIExtensions.h"
@import ObjectiveC;

static NSNumberFormatter* __percentFormatter;
static NSByteCountFormatter* __byteFormatter;

@implementation DTXPerformanceSample (UIExtensions)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__percentFormatter = [NSNumberFormatter new];
		__percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
		
		__byteFormatter = [NSByteCountFormatter new];
		__byteFormatter.countStyle = NSByteCountFormatterCountStyleMemory;
	});
}

- (NSArray<NSString *> *)dtx_sanitizedOpenFiles
{
	NSArray<NSString *>* obj = objc_getAssociatedObject(self, _cmd);
	
	if(obj == nil)
	{
		NSMutableOrderedSet* set = [NSMutableOrderedSet orderedSetWithArray:self.openFiles];
		[set filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (self BEGINSWITH %@)", @"/dev/"]];
		[set filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (self CONTAINS %@)", @".dtxrec/_dtx_recording"]];
		obj = [set array];
		
		objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
	}
	
	return obj;
}

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
