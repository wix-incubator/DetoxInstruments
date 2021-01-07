//
//  DTXRNCPUUsageDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXRNCPUUsageDataExporter.h"

@implementation DTXRNCPUUsageDataExporter

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"cpuUsage"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Time", @"CPU Usage"];
}

@end
