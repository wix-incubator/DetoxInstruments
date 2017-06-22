//
//  DTXCPUInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCPUInspectorDataProvider.h"
#import "DTXPieChartView.h"

@implementation DTXCPUInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXPerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"CPU Usage", @"") description:[NSFormatter.dtx_percentFormatter stringForObjectValue:@(perfSample.cpuUsage)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Active CPU Cores", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(self.document.recording.deviceProcessorCount)]]];
	
	request.content = content;
	
	DTXPieChartView* pieChartView = [[DTXPieChartView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
	
	pieChartView.entries = @[[DTXPieChartEntry entryWithValue:@10 title:nil color:NSColor.redColor], [DTXPieChartEntry entryWithValue:@20 title:nil color:NSColor.greenColor], [DTXPieChartEntry entryWithValue:@30 title:nil color:NSColor.blueColor]];
	
	pieChartView.translatesAutoresizingMaskIntoConstraints = NO;
	[NSLayoutConstraint activateConstraints:@[[pieChartView.widthAnchor constraintEqualToConstant:300], [pieChartView.heightAnchor constraintEqualToConstant:300]]];
	
	DTXInspectorContent* pieChartContent = [DTXInspectorContent new];
	pieChartContent.title = @"Pie Chart";
	pieChartContent.customView = pieChartView;
	
	rv.contentArray = @[request, pieChartContent];
	
	return rv;
}

@end
