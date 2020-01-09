//
//  DTXRNCPUInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNCPUInspectorDataProvider.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXRNStackTraceParser.h"

@implementation DTXRNCPUInspectorDataProvider

- (NSArray *)arrayForStackTrace
{
	return [(DTXReactNativePeroformanceSample*)self.sample stackTrace];
}

- (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat
{
	return [DTXRNStackTraceParser stackTraceFrameStringForObject:obj includeFullFormat:fullFormat];
}

- (NSImage*)imageForObject:(id)obj
{
	NSString* imageName = @"DBGFrameFrameworks";
	
	if([obj isKindOfClass:[NSString class]] == YES)
	{
		if([obj length] == 0)
		{
			imageName = nil;
		}
	}
	else if([obj isKindOfClass:[NSDictionary class]] == YES)
	{
		NSString* sourceFileName = obj[@"sourceFileName"];
		
		if(sourceFileName == nil)
		{
			imageName = nil;
		}
		else {
			if([sourceFileName isEqualToString:@"[native code]"])
			{
				imageName = @"DBGFrameSystem";
			}
			else if([sourceFileName containsString:@"node_modules/react-native/"])
			{
				imageName = @"DBGFrameAppKit";
			}
			else if([sourceFileName containsString:@"node_modules"] == NO)
			{
				imageName = @"DBGFrameUser";
			}
		}
	}
	
	if(imageName.length == 0)
	{
		return nil;
	}
	
	return [NSImage imageNamed:imageName];
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXReactNativePeroformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"CPU Usage", @"") description:[NSFormatter.dtx_percentFormatter stringForObjectValue:@(perfSample.cpuUsage)]]];
	
	request.content = content;
	
//	if(perfSample.recording.dtx_profilingConfiguration.collectJavaScriptStackTraces)
//	{
//		DTXInspectorContent* stackTrace = [self inspectorContentForStackTrace];
//		stackTrace.title = NSLocalizedString(@"Stack Trace", @"");
//
//		rv.contentArray = @[request, stackTrace];
//	}
//	else
//	{
		rv.contentArray = @[request];
//	}
	
	return rv;
}

- (BOOL)canCopyInView:(__kindof NSView *)view
{
//	DTXReactNativePeroformanceSample* perfSample = self.sample;
	return NO; //perfSample.recording.dtx_profilingConfiguration.collectJavaScriptStackTraces;
}

@end
