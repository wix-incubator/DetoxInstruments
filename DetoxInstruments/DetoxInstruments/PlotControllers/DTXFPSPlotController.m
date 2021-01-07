//
//  DTXFPSPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXFPSPlotController.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXFPSDataProvider.h"
#endif
#import "NSColor+UIAdditions.h"

@implementation DTXFPSPlotController

#if ! PROFILER_PREVIEW_EXTENSION
+ (Class)UIDataProviderClass
{
	return [DTXFPSDataProvider class];
}
#endif

- (NSString *)displayName
{
	return NSLocalizedString(@"FPS", @"");
}

- (NSString *)helpTopicName
{
	return @"FPS";
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The FPS instrument captures information about the frame-rate of the profiled app's user interface.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"GPU"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"fps"];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"FPS", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.fpsPlotControllerColor];
}

- (id)transformedValueForFormatter:(id)value
{
	double fps = [value doubleValue];
	if(fps >= 56)
	{
		return @(60);
	}
	
	return @(fps);
}

@end
