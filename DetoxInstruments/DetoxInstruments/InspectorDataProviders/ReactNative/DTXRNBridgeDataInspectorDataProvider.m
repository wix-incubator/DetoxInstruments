//
//  DTXRNBridgeDataInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/08/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXRNBridgeDataInspectorDataProvider.h"

@implementation DTXRNBridgeDataInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXReactNativePerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Data N → JS (Delta)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.bridgeNToJSDataSizeDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Data N → JS (Total)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.bridgeNToJSDataSize)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Data JS → N (Delta)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.bridgeJSToNDataSizeDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Data JS → N (Total)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.bridgeJSToNDataSize)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end
