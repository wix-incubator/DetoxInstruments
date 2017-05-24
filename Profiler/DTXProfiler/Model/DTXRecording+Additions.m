//
//  DTXRecording+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecording+Additions.h"

@implementation DTXRecording (Additions)

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	self.startTimestamp = [NSDate date];
}

@end
