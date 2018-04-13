//
//  DTXTableRowView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXTableRowView.h"
#import "NSColor+UIAdditions.h"

@implementation DTXTableRowView

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		self.wantsLayer = YES;
	}
	
	return self;
}

- (void)layout
{
	[super layout];
	
	if(self.isGroupRowStyle)
	{
		[self.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if([obj isKindOfClass:[NSButton class]])
			{
				obj.frame = (CGRect){4, obj.frame.origin.y, obj.frame.size};
			}
			else
			{
				obj.frame = (CGRect){16, obj.frame.origin.y, obj.frame.size};
			}
		}];
	}
}

@end
