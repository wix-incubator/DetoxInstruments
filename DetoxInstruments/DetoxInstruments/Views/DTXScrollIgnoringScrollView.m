//
//  DTXScrollIgnoringScrollView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 15/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXScrollIgnoringScrollView.h"

@implementation DTXScrollIgnoringScrollView

- (void)scrollWheel:(NSEvent *)theEvent
{
	[[self nextResponder] scrollWheel:theEvent];
}

@end
