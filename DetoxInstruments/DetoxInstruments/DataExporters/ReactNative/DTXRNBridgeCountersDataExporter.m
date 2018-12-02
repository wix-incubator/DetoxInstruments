//
//  DTXRNBridgeCountersDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXRNBridgeCountersDataExporter.h"

@implementation DTXRNBridgeCountersDataExporter

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"bridgeJSToNCallCount", @"bridgeJSToNCallCountDelta", @"bridgeNToJSCallCount", @"bridgeNToJSCallCountDelta"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Time", @"Bridge Calls JS → N (Total)", @"Bridge Calls JS → N (Delta)", @"Bridge Calls N → JS (Total)", @"Bridge Calls N → JS (Delta)"];
}

@end
