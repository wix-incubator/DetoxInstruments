//
//  DTXSample+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSample+Additions.h"
#import "DTXInstruments+CoreDataModel.h"

static NSDictionary<NSString*, NSNumber*>* __classTypeMapping;

@implementation DTXSample (Additions)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__classTypeMapping = @{NSStringFromClass([DTXPerformanceSample class]): @(DTXSampleTypePerformance),
							   NSStringFromClass([DTXAdvancedPerformanceSample class]): @(DTXSampleTypeAdvancedPerformance),
							   NSStringFromClass([DTXThreadPerformanceSample class]): @(DTXSampleTypeThreadPerformance),
							   NSStringFromClass([DTXSampleGroup class]): @(DTXSampleTypeGroup),
							   NSStringFromClass([DTXNetworkSample class]): @(DTXSampleTypeNetwork),
							   NSStringFromClass([DTXTag class]): @(DTXSampleTypeTag),
							   };
	});
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	self.timestamp = [NSDate date];
	self.sampleType = [__classTypeMapping[NSStringFromClass(self.class)] unsignedIntegerValue];
}

@end
