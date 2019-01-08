//
//  DTXPerformanceSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPerformanceSample+UIExtensions.h"
#import "DTXInstrumentsModelUIExtensions.h"

@import ObjectiveC;

static NSNumberFormatter* __percentFormatter;
NSByteCountFormatter* __byteFormatter;

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
		[set filterUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (self CONTAINS %@)", @".dtxprof/_dtx_recording"]];
		obj = [set array];
		
		objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
	}
	
	return obj;
}

@end
