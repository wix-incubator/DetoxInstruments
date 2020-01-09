//
//  DTXThreadCPUUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXThreadCPUUsagePlotController.h"
#import "DTXThreadInfo+UIExtensions.h"
#import "NSColor+UIAdditions.h"
#import "DTXSamplePlotController-Private.h"

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
		
		if([self isMemberOfClass:DTXThreadCPUUsagePlotController.class])
		{
			[NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:DTXPlotSettingsCPUThreadColorize options:NSKeyValueObservingOptionNew context:NULL];
		}
	}
	
	return self;
}

- (void)dealloc
{
	if([self isMemberOfClass:DTXThreadCPUUsagePlotController.class])
	{
		[NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:DTXPlotSettingsCPUThreadColorize];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if([keyPath isEqualToString:DTXPlotSettingsCPUThreadColorize])
	{
		[self _resetCachedPlotColors];
		[self updateLayerHandler];
		
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSImage *)displayIcon
{
	return nil;
}

- (NSString *)displayName
{
	return _threadInfo.friendlyName;
}

- (NSArray<NSColor*>*)plotColors
{
	if([NSUserDefaults.standardUserDefaults boolForKey:DTXPlotSettingsCPUThreadColorize])
	{
		return @[[NSColor randomColorWithSeed:_threadInfo.friendlyName]];
	}
	
	return [super plotColors];
}

- (NSString *)toolTip
{
	return nil;
}

- (NSFont *)titleFont
{
	return [NSFont systemFontOfSize:NSFont.labelFontSize];
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
