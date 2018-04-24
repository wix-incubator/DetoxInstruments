//
//  DTXMemoryUsagePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXMemoryUsagePlotController.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXMemoryDataProvider.h"

@implementation DTXMemoryUsagePlotController

+ (Class)UIDataProviderClass
{
	return [DTXMemoryDataProvider class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Memory Usage", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Memory Usage instrument captures information about the profiled app's memory usage.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"MemoryUsage"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"memoryUsage"];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"Memory", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor colorWithRed:250.0/255.0 green:125.0/255.0 blue:0.0/255.0 alpha:1.0]];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

@end
