//
//  DTXRNCPUUsageDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2018 Wix. All rights reserved.
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
