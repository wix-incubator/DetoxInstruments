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
		DTXInspectorContent* stackTrace = [DTXInspectorContent new];
		stackTrace.title = NSLocalizedString(@"Stack Trace", @"");
		
		NSMutableArray<NSAttributedString*>* stackFrames = [NSMutableArray new];
		NSMutableParagraphStyle* par = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
		par.lineBreakMode = NSLineBreakByTruncatingTail;
		par.paragraphSpacing = 5.0;
		par.allowsDefaultTighteningForTruncation = NO;
		
		[perfSample.stackTrace enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			NSString* stackTraceFrame = nil;
			
			if([obj isKindOfClass:[NSString class]] == YES)
			{
				stackTraceFrame = obj;
			}
			else if([obj isKindOfClass:[NSDictionary class]] == YES)
			{
				stackTraceFrame = [NSString stringWithFormat:@"%@() at %@%@", obj[@"symbolName"], [obj[@"sourceFileName"] lastPathComponent], obj[@"line"] ? [NSString stringWithFormat:@":%@", obj[@"line"]] : @""];
			}
			
			if(stackTraceFrame == nil)
			{
				//Ignore unknown frame format.
				return;
			}
			
			[stackFrames addObject:[[NSAttributedString alloc] initWithString:stackTraceFrame attributes:@{NSParagraphStyleAttributeName: par, NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:10]}]];
		}];
		 
		stackTrace.stackFrames = stackFrames;
		
		rv.contentArray = @[request, stackTrace];
	}
	else
	{
		rv.contentArray = @[request];
	}
	
	return rv;
}

@end
