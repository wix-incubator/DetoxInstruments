//
//  DTXFPSDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXFPSDataExporter.h"

@implementation DTXFPSDataExporter

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"fps"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Time", @"FPS"];
}

@end
