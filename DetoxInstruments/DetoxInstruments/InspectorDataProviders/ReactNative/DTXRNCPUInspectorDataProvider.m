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
		
//		\#(\d+) (.*)\(\) at (.*?)(:(\d+))?$
		NSRegularExpression* expr = [NSRegularExpression regularExpressionWithPattern:@"\\#(\\d+) (.*)\\(\\) at (.*?)(:(\\d+))?$" options:0 error:NULL];
		
		NSTextCheckingResult* match = [expr matchesInString:stackTraceFrame options:0 range:NSMakeRange(0, stackTraceFrame.length)].firstObject;
		
		if(match.numberOfRanges == 6)
		{
			NSString* funcName = [obj substringWithRange:[match rangeAtIndex:2]];
			NSString* codeURLString = [obj substringWithRange:[match rangeAtIndex:3]];
			
			NSNumber* line;
			__unused NSNumber* column = @0;
			
			if([match rangeAtIndex:4].location != NSNotFound)
			{
				NSInteger lineNumber = [obj substringWithRange:[match rangeAtIndex:5]].integerValue;
				
				line = @(lineNumber);
			}
			
			NSString* sourceFileName = codeURLString;
			
			NSString* symbolName = funcName;

			stackTraceFrame = [NSString stringWithFormat:@"%@() at %@%@", symbolName, fullFormat ? sourceFileName : [sourceFileName lastPathComponent], line ? [NSString stringWithFormat:@":%@", line] : @""];
		}
	}
	else if([obj isKindOfClass:[NSDictionary class]] == YES)
	{
		stackTraceFrame = [NSString stringWithFormat:@"%@() at %@%@", obj[@"symbolName"], fullFormat ? obj[@"sourceFileName"] : [obj[@"sourceFileName"] lastPathComponent], obj[@"line"] ? [NSString stringWithFormat:@":%@", obj[@"line"]] : @""];
	}
	
	if([stackTraceFrame stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0)
	{
		stackTraceFrame = @"<native>";
	}
	
	return stackTraceFrame;
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
