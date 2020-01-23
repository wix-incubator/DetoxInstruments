//
//  DTXRNBridgeCallsInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/08/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNBridgeCallsInspectorDataProvider.h"

@implementation DTXRNBridgeCallsInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXReactNativePerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Calls N → JS (Delta)", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(perfSample.bridgeNToJSCallCountDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Calls N → JS (Total)", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(perfSample.bridgeNToJSCallCount)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Calls JS → N (Delta)", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(perfSample.bridgeJSToNCallCountDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Bridge Calls JS → N (Total)", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(perfSample.bridgeJSToNCallCount)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end
