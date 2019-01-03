//
//  DTXThreadCPUUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXThreadCPUUsagePlotController.h"
#import "DTXThreadInfo+UIExtensions.h"

@implementation DTXThreadCPUUsagePlotController
{
	DTXThreadInfo* _threadInfo;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document threadInfo:(DTXThreadInfo*)threadInfo isForTouchBar:(BOOL)isForTouchBar
{
	self = [super initWithDocument:document isForTouchBar:isForTouchBar];
	
	if(self)
	{
		_threadInfo = threadInfo;
	}
	
	return self;
}

- (NSImage *)displayIcon
{
	return nil;
}

- (NSString *)displayName
{
	return _threadInfo.friendlyName;
}

- (NSString *)toolTip
{
	return nil;
}

- (NSFont *)titleFont
{
	return [NSFont systemFontOfSize:10];
}

- (CGFloat)requiredHeight
{
	return 22;
}

- (NSPredicate*)predicateForPerformanceSamples
{
	return [NSPredicate predicateWithFormat:@"threadInfo == %@", _threadInfo];
}

+ (Class)classForPerformanceSamples
{
	return [DTXThreadPerformanceSample class];
}

- (BOOL)canReceiveFocus
{
	return NO;
}

@end
