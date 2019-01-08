//
//  DTXBox.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/3/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXBox.h"

@implementation DTXBox

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	[super updateLayer];
	
	self.layer.cornerRadius = self.cornerRadius;
}

@end
