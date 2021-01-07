//
//  DTXMemoryInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXMemoryInspectorDataProvider.h"

@implementation DTXMemoryInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXPerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Memory Usage", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.memoryUsage)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end
