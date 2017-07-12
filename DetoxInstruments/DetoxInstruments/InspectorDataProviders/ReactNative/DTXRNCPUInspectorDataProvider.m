//
//  DTXRNCPUInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRNCPUInspectorDataProvider.h"
#import "DTXRecording+UIExtensions.h"

@implementation DTXRNCPUInspectorDataProvider

- (NSArray *)arrayForStackTrace
{
	return [(DTXReactNativePeroformanceSample*)self.sample stackTrace];
}

- (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat
{
	NSString* stackTraceFrame = nil;
	
	if([obj isKindOfClass:[NSString class]] == YES)
	{
		stackTraceFrame = obj;
	}
	else if([obj isKindOfClass:[NSDictionary class]] == YES)
	{
		stackTraceFrame = [NSString stringWithFormat:@"%@() at %@%@", obj[@"symbolName"], fullFormat ? obj[@"sourceFileName"] : [obj[@"sourceFileName"] lastPathComponent], obj[@"line"] ? [NSString stringWithFormat:@":%@", obj[@"line"]] : @""];
	}
	
	if(stackTraceFrame.length == 0)
	{
		stackTraceFrame = @"<idle>";
	}
	
	return stackTraceFrame;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXReactNativePeroformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"CPU Usage", @"") description:[NSFormatter.dtx_percentFormatter stringForObjectValue:@(perfSample.cpuUsage)]]];
	
	request.content = content;
	
	if(perfSample.recording.dtx_profilingConfiguration.collectJavaScriptStackTraces)
	{
		DTXInspectorContent* stackTrace = [self inspectorContentForStackTrace];
		stackTrace.title = NSLocalizedString(@"Stack Trace", @"");
		
		rv.contentArray = @[request, stackTrace];
	}
	else
	{
		rv.contentArray = @[request];
	}
	
	return rv;
}

- (BOOL)canCopy
{
	DTXReactNativePeroformanceSample* perfSample = self.sample;
	return perfSample.recording.dtx_profilingConfiguration.collectJavaScriptStackTraces;
}

@end
