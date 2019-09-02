//
//  DTXCPUUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXCPUUsagePlotController.h"
#import "NSFormatter+PlotFormatters.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXCPUDataProvider.h"
#endif
#import "DTXScatterPlotView.h"
#import "NSColor+UIAdditions.h"

@implementation DTXCPUUsagePlotController

- (instancetype)initWithDocument:(DTXRecordingDocument *)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super initWithDocument:document isForTouchBar:isForTouchBar];
	
	if(self && [self isMemberOfClass:DTXCPUUsagePlotController.class])
	{
		[NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:DTXPlotSettingsCPUDisplayMTOverlay options:NSKeyValueObservingOptionNew context:NULL];
	}
	
	return self;
}

- (void)dealloc
{
	if([self isMemberOfClass:DTXCPUUsagePlotController.class])
	{
		[NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:DTXPlotSettingsCPUDisplayMTOverlay];
	}
}

#if ! PROFILER_PREVIEW_EXTENSION
+ (Class)UIDataProviderClass
{
	return [DTXCPUDataProvider class];
}
#endif

- (NSString *)displayName
{
	return NSLocalizedString(@"CPU Usage", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The CPU Usage instrument captures information about the profiled app's load on the CPU.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"CPUUsage"];
}

- (NSString *)helpTopicName
{
	return @"CPUUsage";
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"cpuUsage"];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"CPU Usage", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.cpuUsagePlotControllerColor];
}

- (NSArray<NSColor *> *)additionalPlotColors
{
	return @[[NSColor randomColorWithSeed:DTXThreadInfo.mainThreadFriendlyName]];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_percentFormatter];
}

+ (NSFormatter *)additionalFormatterForDataPresentation
{
	return [NSFormatter dtx_mainThreadFormatter];
}

- (id)transformedValueForFormatter:(id)value
{
	return @(MAX([value doubleValue], 0.0));
}

- (CGFloat)minimumValueForPlotHeight
{
	return 1.0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if([keyPath isEqualToString:DTXPlotSettingsCPUDisplayMTOverlay])
	{
		[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj reloadData];
		}];
		
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark DTXScatterPlotViewDataSource

- (BOOL)hasAdditionalPointsForPlotView:(DTXScatterPlotView *)plotView
{
	return [self isMemberOfClass:DTXCPUUsagePlotController.class] && self.document.firstRecording.dtx_profilingConfiguration.recordThreadInformation && [NSUserDefaults.standardUserDefaults boolForKey:DTXPlotSettingsCPUDisplayMTOverlay];
}

- (DTXScatterPlotViewPoint *)plotView:(DTXScatterPlotView *)plotView additionalPointAtIndex:(NSUInteger)idx
{
	NSUInteger plotIdx = plotView.plotIndex;
	
	DTXPerformanceSample* sample = [self samplesForPlotIndex:plotIdx][idx];
	DTXThreadPerformanceSample* threadSample = sample.threadSamples.firstObject;
	
	DTXScatterPlotViewPoint* rv = [DTXScatterPlotViewPoint new];
	rv.x = 0;
	rv.y = threadSample == nil ? 0.0 : [[self transformedValueForFormatter:@(threadSample.cpuUsage)] doubleValue];
	
	return rv;
}

@end
