//
//  DTXFPSPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXFPSPlotController.h"

@implementation DTXFPSPlotController

- (NSString *)displayName
{
	return NSLocalizedString(@"FPS", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"graphicsDriverUtility"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"fps"];
}

- (NSArray<NSString *> *)plotTitles
{
	return @[NSLocalizedString(@"FPS", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor colorWithRed:198.0/255.0 green:109.0/255.0 blue:218.0/255.0 alpha:1.0]];
}

@end
