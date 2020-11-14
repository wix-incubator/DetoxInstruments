//
//  DTXHeaderAccessoryViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan on 9/2/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXHeaderAccessoryViewController.h"
#import "NSAppearance+UIAdditions.h"

@interface NSTitlebarAccessoryViewController ()

- (NSRect)_currentClipViewFrame;

@end

@implementation DTXHeaderAccessoryViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSBox* box = (id)self.view;
	box.boxType = NSBoxCustom;
	box.cornerRadius = 0;
	if(@available(macOS 11.0, *))
	{
		box.fillColor = NSColor.clearColor;
	}
	else
	{
		box.fillColor = [NSColor colorWithName:@"HeaderBackgroundColor" dynamicProvider:^NSColor * _Nonnull(NSAppearance * _Nonnull appearance) {
			if(appearance.isDarkAppearance)
			{
				return NSColor.clearColor;
			}
			else
			{
				return NSColor.clearColor;
			}
		}];
	}
}

- (NSView *)headerView
{
	return self.view.subviews.lastObject;
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
