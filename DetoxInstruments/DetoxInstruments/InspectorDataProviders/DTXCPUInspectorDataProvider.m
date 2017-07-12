//
//  DTXCPUInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCPUInspectorDataProvider.h"
#import "DTXPieChartView.h"
#import "DTXRecording+UIExtensions.h"

@implementation DTXCPUInspectorDataProvider

- (NSArray *)arrayForStackTrace
{
	return [(DTXAdvancedPerformanceSample*)self.sample heaviestStackTrace];
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
		if(fullFormat)
		{
			stackTraceFrame = [NSString stringWithFormat:@"%-35s 0x%016llx %@ + %@", [obj[@"image"] UTF8String], (uint64_t)[(obj[@"address"] ?: @0) unsignedIntegerValue], obj[@"symbol"], obj[@"offset"]];
		}
		else
		{
			stackTraceFrame = [NSString stringWithFormat:@"%@ + %@", obj[@"symbol"], obj[@"offset"]];
		}
	}
	
	return stackTraceFrame;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	__kindof DTXPerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"CPU Usage", @"") description:[NSFormatter.dtx_percentFormatter stringForObjectValue:@(perfSample.cpuUsage)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Active CPU Cores", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(self.document.recording.deviceProcessorCount)]]];
	
	request.content = content;
	
//	DTXPieChartView* pieChartView = [[DTXPieChartView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
//
//	pieChartView.entries = @[[DTXPieChartEntry entryWithValue:@10 title:nil color:NSColor.redColor], [DTXPieChartEntry entryWithValue:@20 title:nil color:NSColor.greenColor], [DTXPieChartEntry entryWithValue:@30 title:nil color:NSColor.blueColor]];
//
//	pieChartView.translatesAutoresizingMaskIntoConstraints = NO;
//	[NSLayoutConstraint activateConstraints:@[[pieChartView.widthAnchor constraintEqualToConstant:300], [pieChartView.heightAnchor constraintEqualToConstant:300]]];
//
//	DTXInspectorContent* pieChartContent = [DTXInspectorContent new];
//	pieChartContent.title = @"Pie Chart";
//	pieChartContent.customView = pieChartView;
	
	if(perfSample.recording.dtx_profilingConfiguration.collectStackTraces)
	{
		DTXInspectorContent* stackTrace = [self inspectorContentForStackTrace];
		stackTrace.title = NSLocalizedString(@"Heaviest Stack Trace", @"");
		
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
	return [self.sample isKindOfClass:[DTXAdvancedPerformanceSample class]];
}

@end
