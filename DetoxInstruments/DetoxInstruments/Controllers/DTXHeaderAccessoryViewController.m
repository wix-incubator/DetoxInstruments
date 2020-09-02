//
//  DTXHeaderAccessoryViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan on 9/2/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXHeaderAccessoryViewController.h"

@interface NSTitlebarAccessoryViewController ()

- (NSRect)_currentClipViewFrame;

@end

@interface AAView : NSView @end
@implementation AAView

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
}

@end

@implementation DTXHeaderAccessoryViewController

- (NSView *)headerView
{
	return self.view.subviews.firstObject;
}

- (CGFloat)fullScreenMinHeight
{
	return 20;
}

- (NSRect)_currentClipViewFrame
{
	NSRect rv = [super _currentClipViewFrame];
	rv.size.height = 20;
	return rv;
}

@end
