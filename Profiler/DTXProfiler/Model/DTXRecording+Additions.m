//
//  DTXRecording+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecording+Additions.h"
@import ObjectiveC;

@implementation DTXRecording (Additions)

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	self.startTimestamp = [NSDate date];
}

- (DTXProfilingConfiguration *)dtx_profilingConfiguration
{
	if(self.profilingConfiguration == nil)
	{
		return nil;
	}
	
	DTXProfilingConfiguration* obj = objc_getAssociatedObject(self, _cmd);
	
	if(obj == nil)
	{
		obj = [[DTXProfilingConfiguration alloc] initWithCoder:(id)self.profilingConfiguration];
		objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
	}
	
	return obj;
}

@end
