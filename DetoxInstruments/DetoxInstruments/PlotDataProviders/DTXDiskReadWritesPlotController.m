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
	return NSLocalizedString(@"Disk Usage", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"fileActivity"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"diskReadsDelta", @"diskWritesDelta"];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor.systemGreenColor colorWithAlphaComponent:1.0], [NSColor.systemRedColor colorWithAlphaComponent:1.0]];
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
