//
//  DTXMemoryUsageDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXMemoryUsageDataExporter.h"

@implementation DTXMemoryUsageDataExporter

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"memoryUsage"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Time", @"Memory Usage"];
}

@end
