//
//  DTXRNBridgeDataDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNBridgeDataDataExporter.h"

@implementation DTXRNBridgeDataDataExporter

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"bridgeJSToNDataSize", @"bridgeJSToNDataSizeDelta", @"bridgeNToJSDataSize", @"bridgeNToJSDataSizeDelta"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Time", @"Bridge Data JS → N (Total)", @"Bridge Data JS → N (Delta)", @"Bridge Data N → JS (Total)", @"Bridge Data N → JS (Delta)"];
}

@end
