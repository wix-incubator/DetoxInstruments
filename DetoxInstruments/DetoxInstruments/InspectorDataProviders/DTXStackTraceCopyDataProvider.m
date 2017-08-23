//
//  DTXStackTraceCopyDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXStackTraceCopyDataProvider.h"

@implementation DTXStackTraceCopyDataProvider

+ (NSFont*)fontForStackTraceDisplay
{
	static NSFont* font;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		font = [NSFont fontWithName:@"SFMono-Regular" size:10];
		
		if(font == nil)
		{
			//There is no SFMono in the system, use Menlo instead.
			font = [NSFont fontWithName:@"Menlo" size:10];
		}
	});
	
	return font;
}

- (NSArray*)arrayForStackTrace
{
	return nil;
}

- (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat
{
	return nil;
}

- (void)copy:(id)sender targetView:(__kindof NSView *)targetView
{
	NSIndexSet* selectedRowIndices = [targetView selectedRowIndexes];
	if([targetView numberOfSelectedRows] == 0)
	{
		selectedRowIndices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [targetView numberOfRows])];
	}
	
	NSMutableString* rv = [NSMutableString new];
	
	[selectedRowIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
		id obj = self.arrayForStackTrace[idx];
		
		NSString* stackTraceFrame = [self stackTraceFrameStringForObject:obj includeFullFormat:YES];
		
		if(stackTraceFrame == nil)
		{
			//Ignore unknown frame format.
			return;
		}
		
		[rv appendString:[NSString stringWithFormat:@"%-4ld%@", idx, stackTraceFrame]];
		[rv appendString:@"\n"];
	}];
	
	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:[rv stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] forType:NSPasteboardTypeString];
}

- (DTXInspectorContent*)inspectorContentForStackTrace
{
	DTXInspectorContent* stackTrace = [DTXInspectorContent new];
	
	NSMutableArray<DTXStackTraceFrame*>* stackFrames = [NSMutableArray new];
	NSMutableParagraphStyle* par = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
	par.lineBreakMode = NSLineBreakByTruncatingTail;
	par.paragraphSpacing = 5.0;
	par.allowsDefaultTighteningForTruncation = NO;
	
	[self.arrayForStackTrace enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* stackTraceFrame = [self stackTraceFrameStringForObject:obj includeFullFormat:NO];
		
		if(stackTraceFrame == nil)
		{
			//Ignore unknown frame format.
			return;
		}
		
		DTXStackTraceFrame* frame = [DTXStackTraceFrame new];
		frame.stackFrameText = [[NSAttributedString alloc] initWithString:stackTraceFrame attributes:@{NSParagraphStyleAttributeName: par, NSFontAttributeName: [self.class fontForStackTraceDisplay]}];
		frame.fullStackFrameText = [self stackTraceFrameStringForObject:obj includeFullFormat:YES];
		frame.stackFrameIcon = [self imageForObject:obj];
		
		[stackFrames addObject:frame];
	}];
	
	stackTrace.stackFrames = stackFrames;
	stackTrace.setupForWindowWideCopy = YES;

	return stackTrace;
}

- (NSImage*)imageForObject:(id)obj
{
	return [NSImage imageNamed:@"DBGFrameGeneric"];;
}

@end
