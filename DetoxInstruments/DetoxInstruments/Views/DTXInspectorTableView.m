//
//  DTXInspectorTableView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 15/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXInspectorTableView.h"

@implementation DTXInspectorTableView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	if (@available(macOS 11.0, *))
	{
		self.style = NSTableViewStyleFullWidth;
	}
}

- (void)drawGridInClipRect:(NSRect)clipRect
{
	NSRect lastRowRect = [self rectOfRow:[self numberOfRows] - 1];
	NSRect myClipRect = NSMakeRect(0, 0, lastRowRect.size.width, NSMaxY(lastRowRect));
	NSRect finalClipRect = NSIntersectionRect(clipRect, myClipRect);
	[super drawGridInClipRect:finalClipRect];
}

@end
