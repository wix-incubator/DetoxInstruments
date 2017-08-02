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
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
	return @[[NSColor.systemGreenColor colorWithAlphaComponent:1.0], [NSColor.systemRedColor colorWithAlphaComponent:1.0]];
#else
	return @[[NSColor.greenColor colorWithAlphaComponent:1.0], [NSColor.redColor colorWithAlphaComponent:1.0]];
#endif
}

- (NSArray<NSString *> *)plotTitles
{
	return @[NSLocalizedString(@"Reads", @""), NSLocalizedString(@"Writes", @"")];
}

- (BOOL)isStepped
{
	return YES;
}

- (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

@end
