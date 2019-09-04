//
//  DTXDiskInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXDiskInspectorDataProvider.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXPerformanceSample+UIExtensions.h"
 
@implementation DTXDiskInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXPerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Read (Delta)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskReadsDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Read (Total)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskReads)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Written (Delta)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskWritesDelta)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Written (Total)", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(perfSample.diskWrites)]]];
	
	request.content = content;
	
	NSMutableArray* contentArray = @[request].mutableCopy;
	
	if(self.document.firstRecording.dtx_profilingConfiguration.collectOpenFileNames)
	{
		DTXInspectorContent* stackTrace = [self inspectorContentForStackTrace];
		stackTrace.title = NSLocalizedString(@"Open Files", @"");
		
		[contentArray addObject:stackTrace];
	}
	
	rv.contentArray = contentArray;
	
	return rv;
}

- (DTXInspectorContent*)inspectorContentForStackTrace
{
	DTXInspectorContent* stackTrace = [DTXInspectorContent new];
	DTXPerformanceSample* perfSample = self.sample;
	
	NSMutableArray<DTXStackTraceFrame*>* stackFrames = [NSMutableArray new];
	NSMutableParagraphStyle* par = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
	par.lineBreakMode = NSLineBreakByTruncatingMiddle;
//	par.paragraphSpacing = 5.0;
	par.allowsDefaultTighteningForTruncation = NO;
	
	NSArray* arrayForStackTrace = perfSample.dtx_sanitizedOpenFiles;
	if(arrayForStackTrace.count == 0)
	{
		arrayForStackTrace = @[@""];
	}
	
	[arrayForStackTrace enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* stackTraceFrame = [self stackTraceFrameStringForObject:obj includeFullFormat:NO];
		
		if(stackTraceFrame == nil)
		{
			//Ignore unknown frame format.
			return;
		}
		
		DTXStackTraceFrame* frame = [DTXStackTraceFrame new];
		frame.stackFrameText = [[NSAttributedString alloc] initWithString:stackTraceFrame attributes:@{NSParagraphStyleAttributeName: par, NSFontAttributeName:[NSFont systemFontOfSize:10 weight:NSFontWeightRegular]}];
		frame.fullStackFrameText = [self stackTraceFrameStringForObject:obj includeFullFormat:YES];
		
		[stackFrames addObject:frame];
	}];
	
	stackTrace.stackFrames = stackFrames;
	
	return stackTrace;
}

- (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat
{
	NSString* stackTraceFrame = nil;
	
	if([obj isKindOfClass:[NSString class]] == YES)
	{
		stackTraceFrame = obj;
	}
	
	return stackTraceFrame;
}

- (BOOL)canCopyInView:(__kindof NSView *)view
{
	return self.document.firstRecording.dtx_profilingConfiguration.collectOpenFileNames;
}

- (void)copyInView:(__kindof NSView *)view sender:(id)sender
{
	DTXPerformanceSample* perfSample = self.sample;

	NSIndexSet* selectedRowIndices = [view selectedRowIndexes];
	if([view numberOfSelectedRows] == 0)
	{
		selectedRowIndices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [view numberOfRows])];
	}

	NSMutableString* rv = [NSMutableString new];

	[selectedRowIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
		id obj = perfSample.dtx_sanitizedOpenFiles[idx];

		NSString* stackTraceFrame = [self stackTraceFrameStringForObject:obj includeFullFormat:YES];

		if(stackTraceFrame == nil)
		{
			//Ignore unknown frame format.
			return;
		}

		[rv appendString:stackTraceFrame];
		[rv appendString:@"\n"];
	}];

	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:[rv stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] forType:NSPasteboardTypeString];
}

@end
