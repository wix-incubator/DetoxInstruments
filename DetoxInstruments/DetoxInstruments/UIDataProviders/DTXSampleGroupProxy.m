//
//  DTXSampleGroupProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSampleGroupProxy.h"

@implementation DTXSampleGroupProxy

@end

@implementation DTXGroupInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXSampleGroupProxy* proxy = (id)self.sample;
	
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Group", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Name", @"") description:proxy.name]];
	
	NSTimeInterval ti = [proxy.timestamp timeIntervalSinceReferenceDate] - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start", @"") description:[[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)]]];
	
	ti = [proxy.closeTimestamp ?: self.document.recording.endTimestamp timeIntervalSinceReferenceDate] - [self.document.recording.startTimestamp timeIntervalSinceReferenceDate];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"End", @"") description:[[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end
