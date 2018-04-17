//
//  DTXDetailOutlineView.m
//  Instruments
//
//  Created by Leo Natan (Wix) on 15/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDetailOutlineView.h"
@import ObjectiveC;

@implementation DTXDetailOutlineView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	struct objc_super mySuper = {
		.receiver = self,
		.super_class = NSTableView.class
	};
	
	NSRect (*objc_superAllocTyped)(struct objc_super *, SEL, NSInteger, NSInteger) = (void *)&objc_msgSendSuper_stret;
	NSRect rv = objc_superAllocTyped(&mySuper, _cmd, column, row);
	
	return rv;
}

@end
