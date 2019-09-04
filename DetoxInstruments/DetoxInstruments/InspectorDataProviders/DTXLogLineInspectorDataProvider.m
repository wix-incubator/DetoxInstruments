//
//  DTXLogLineInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/08/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXLogLineInspectorDataProvider.h"
#import "DTXStackTraceCopyDataProvider.h"
#import "DTXInstrumentsModelUIExtensions.h"

@implementation DTXLogLineInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXLogSample* logSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = logSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	
	request.content = content;
	
	DTXInspectorContent* logLineInfo = [DTXInspectorContent new];
	logLineInfo.title = NSLocalizedString(@"Log", @"");
	
	content = [NSMutableArray new];
	
	NSMutableParagraphStyle* par = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	par.hyphenationFactor = 1.0;
	par.tighteningFactorForTruncation = 0.0;
	NSAttributedString* attr = [[NSAttributedString alloc] initWithString:logSample.line attributes:@{NSFontAttributeName: [DTXStackTraceCopyDataProvider fontForStackTraceDisplay], NSForegroundColorAttributeName: NSColor.labelColor, NSParagraphStyleAttributeName: par}];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Line", @"") attributedDescription:attr]];
	
	logLineInfo.content = content;
	
	if(logSample.objects.count > 0)
	{
		DTXInspectorContent* objectsContent = [DTXInspectorContent new];
		objectsContent.title = NSLocalizedString(@"Logged Objects", @"");
		objectsContent.objects = logSample.objects;
		
		rv.contentArray = @[request, objectsContent, logLineInfo];
	}
	else
	{
		rv.contentArray = @[request, logLineInfo];
	}
	
	return rv;
}

- (BOOL)canCopyInView:(__kindof NSView *)view
{
	DTXLogSample* logSample = self.sample;
	
	return logSample.objects.count > 0;
}

- (void)copyInView:(__kindof NSView *)view sender:(id)sender
{
	NSOutlineView* outlineView = view;
	NSValue* val = [outlineView itemAtRow:[outlineView selectedRow]];
	
	id obj = val.nonretainedObjectValue;
	
	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:[obj description] forType:NSPasteboardTypeString];
}

@end
