//
//  DTXThreadPerformanceSample+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 1/9/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXThreadPerformanceSample+Additions.h"
#import "DTXSample+Additions.h"

@implementation DTXThreadPerformanceSample (Additions)

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	self.timestamp = [NSDate date];
	self.sampleType = [DTXSample sampleTypeFromClass:self.class];
}

@end
