//
//  DTXDiskReadWritesPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDiskReadWritesPlotController.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXDiskDataProvider.h"

@implementation DTXDiskReadWritesPlotController

+ (Class)UIDataProviderClass
{
	return [DTXDiskDataProvider class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Disk Activity", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Disk Activity instrument captures information about the profiled app's disk reads and writes.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"DiskActivity"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"diskReadsDelta", @"diskWritesDelta"];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.diskReadPlotControllerColor, NSColor.diskWritePlotControllerColor];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"Reads", @""), NSLocalizedString(@"Writes", @"")];
}

- (BOOL)isStepped
{
	return YES;
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

@end
