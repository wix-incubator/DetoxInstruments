//
//  DTXAutomaticallyAnimatingProgressIndicator.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/15/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXAutomaticallyAnimatingProgressIndicator.h"

@implementation DTXAutomaticallyAnimatingProgressIndicator

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.usesThreadedAnimation = YES;
	[self startAnimation:nil];
}


@end
