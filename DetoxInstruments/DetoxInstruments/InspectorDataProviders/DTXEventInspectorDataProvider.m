//
//  DTXEventInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/4/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXEventInspectorDataProvider.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXRNStackTraceParser.h"
#import "DTXEventStatusPrivate.h"
#import "DTXSignpostAdditionalInfoEndProxy.h"

@implementation DTXEventInspectorDataProvider

- (instancetype)initWithSample:(__kindof DTXSample *)sample document:(DTXRecordingDocument *)document
{
	id sampleToUse = sample;
	if([sampleToUse isKindOfClass:DTXSignpostAdditionalInfoEndProxy.class])
	{
		sampleToUse = [(DTXSignpostAdditionalInfoEndProxy*)sampleToUse sample];
	}
	
	return [super initWithSample:sampleToUse document:document];
}

- (NSArray *)arrayForStackTrace
{
	DTXSignpostSample* eventSample = self.sample;
	
//	DTXRNSymbolicateJSCBacktrace
	
	return eventSample.stackTrace;
}

- (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat
{
	return [DTXRNStackTraceParser stackTraceFrameStringForObject:obj includeFullFormat:fullFormat];
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXSignpostSample* eventSample = self.sample;
	
	DTXInspectorContent* general = [DTXInspectorContent new];
	general.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = eventSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Type", @"") description:eventSample.eventTypeString]];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Category", @"") description:eventSample.category]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Name", @"") description:eventSample.name]];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Status", @"") description:eventSample.eventStatusString]];
	
	general.content = content;
	NSMutableArray* contentArray = @[general].mutableCopy;
	
	DTXInspectorContent* additionalInfo = [DTXInspectorContent new];
	additionalInfo.title = NSLocalizedString(@"Message", @"");
	content = [NSMutableArray new];
	
	if(eventSample.isEvent == NO)
	{
		if(eventSample.additionalInfoStart.length > 0)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start", @"") description:eventSample.additionalInfoStart]];
		}
		
		if(eventSample.additionalInfoEnd.length > 0)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"End", @"") description:eventSample.additionalInfoEnd]];
		}
	}
	else
	{
		if(eventSample.additionalInfoStart.length > 0)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Message", @"") description:eventSample.additionalInfoStart]];
		}
	}
	
	additionalInfo.content = content;
	
	if(additionalInfo.content.count > 0)
	{
		[contentArray addObject:additionalInfo];
	}
	
	DTXInspectorContent* threads = [DTXInspectorContent new];
	threads.title = NSLocalizedString(@"Threads", @"");
	content = [NSMutableArray new];
	
	if(eventSample.isEvent == NO)
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Starting Thread", @"") description:eventSample.startThread.friendlyName]];
		
		NSString* endString, *durationString;
		
		if(eventSample.endTimestamp)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Ending Thread", @"") description:eventSample.endThread.friendlyName]];
		}
	}
	else
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Thread", @"") description:eventSample.startThread.friendlyName]];
	}
	
	threads.content = content;
	
	[contentArray addObject:threads];
	
	DTXInspectorContent* timing = [DTXInspectorContent new];
	timing.title = NSLocalizedString(@"Timing", @"");
	content = [NSMutableArray new];
	
	if(eventSample.isEvent == NO)
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
		
		NSString* endString, *durationString;
		
		if(eventSample.endTimestamp)
		{
			ti = eventSample.endTimestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
			endString = [NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)];
			durationString = [NSFormatter.dtx_durationFormatter stringFromTimeInterval:eventSample.duration];
		}
		else
		{
			endString = @"—";
			durationString = @"—";
		}
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"End", @"") description:endString]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Duration", @"") description:durationString]];
	}
	else
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	}
	
	timing.content = content;
	
	[contentArray addObject:timing];
	
	if(eventSample.isTimer == YES && eventSample.stackTrace != nil)
	{
		DTXInspectorContent* stackTrace = [self inspectorContentForStackTrace];
		stackTrace.title = NSLocalizedString(@"Stack Trace", @"");
		[contentArray addObject:stackTrace];
	}
	
	rv.contentArray = contentArray;
	
	return rv;
}

@end
