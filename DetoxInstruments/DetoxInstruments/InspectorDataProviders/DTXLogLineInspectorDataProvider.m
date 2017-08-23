//
//  DTXLogLineInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXLogLineInspectorDataProvider.h"
#import "DTXStackTraceCopyDataProvider.h"

@implementation DTXLogLineInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXLogSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	
	request.content = content;
	
	DTXInspectorContent* logLineInfo = [DTXInspectorContent new];
	logLineInfo.title = NSLocalizedString(@"Log", @"");
	
	content = [NSMutableArray new];
	
	NSMutableParagraphStyle* par = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	par.hyphenationFactor = 1.0;
	par.tighteningFactorForTruncation = 0.0;
	NSAttributedString* attr = [[NSAttributedString alloc] initWithString:perfSample.line attributes:@{NSFontAttributeName: [DTXStackTraceCopyDataProvider fontForStackTraceDisplay], NSForegroundColorAttributeName: NSColor.textColor, NSParagraphStyleAttributeName: par}];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Line", @"") attributedDescription:attr]];
	
	logLineInfo.content = content;
	
	rv.contentArray = @[request, logLineInfo];
	
	return rv;
}

@end
