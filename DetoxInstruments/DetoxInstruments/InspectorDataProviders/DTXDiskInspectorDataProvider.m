//
//  DTXDiskInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDiskInspectorDataProvider.h"
 
@implementation DTXDiskInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXPerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Read (Delta)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskReadsDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Read (Total)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskReads)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Written (Delta)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskWritesDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Written (Total)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskWrites)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end
