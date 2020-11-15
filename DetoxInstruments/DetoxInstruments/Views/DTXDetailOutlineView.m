//
//  DTXDetailOutlineView.m
//  Instruments
//
//  Created by Leo Natan (Wix) on 15/08/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXDetailOutlineView.h"
@import ObjectiveC;

@implementation DTXDetailOutlineView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	if (@available(macOS 11.0, *))
	{
		self.style = NSTableViewStyleInset;
	}
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	if(_respectsOutlineCellFraming)
	{
		return [super frameOfCellAtColumn:column row:row];
	}
	
	struct objc_super mySuper = {
		.receiver = self,
		.super_class = NSTableView.class
	};
	
	NSRect (*objc_superAllocTyped)(struct objc_super *, SEL, NSInteger, NSInteger) = (void *)&
#if defined(__x86_64__)
	objc_msgSendSuper_stret
#elif defined(__aarch64__)
	objc_msgSendSuper
#else
#error Unsupported arch
#endif
	;
	
	NSRect rv = objc_superAllocTyped(&mySuper, _cmd, column, row);
	
	return rv;
}

- (void)layout
{
	[super layout];
	
	if((self.tableColumns.lastObject.resizingMask & NSTableColumnAutoresizingMask) == NSTableColumnAutoresizingMask)
	{
		[self sizeLastColumnToFit];
	}
}

@end
