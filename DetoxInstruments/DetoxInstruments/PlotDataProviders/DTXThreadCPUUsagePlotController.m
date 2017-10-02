//
//  DTXThreadCPUUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXThreadCPUUsagePlotController.h"

@implementation DTXThreadCPUUsagePlotController
{
	DTXThreadInfo* _threadInfo;
}

- (instancetype)initWithDocument:(DTXDocument*)document threadInfo:(DTXThreadInfo*)threadInfo
{
	self = [super initWithDocument:document];
	
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
	return _threadInfo.name.length > 0 ? _threadInfo.name : _threadInfo.number == 0 ? NSLocalizedString(@"Main Thread", @"") : [NSString stringWithFormat:NSLocalizedString(@"Thread %@", @""), @(_threadInfo.number)];
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

- (Class)classForPerformanceSamples
{
	return [DTXThreadPerformanceSample class];
}

- (BOOL)canReceiveFocus
{
	return NO;
}

@end
