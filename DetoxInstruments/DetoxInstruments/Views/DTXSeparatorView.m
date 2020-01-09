//
//  DTXSeparatorView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 2/7/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXSeparatorView.h"

@implementation DTXSeparatorView

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		self.wantsLayer = YES;
	}
	
	return self;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	self.layer.backgroundColor = NSColor.gridColor.CGColor;
}

@end
