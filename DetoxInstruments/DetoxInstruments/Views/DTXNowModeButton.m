//
//  DTXNowModeButton.m
//  DetoxInstruments
//
//  Created by Leo Natan on 9/8/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXNowModeButton.h"

@implementation DTXNowModeButton

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.state = self.state;
}

- (void)mouseDown:(NSEvent *)event
{
	[super mouseDown:event];
	
	[self _resetImage];
}

- (void)mouseUp:(NSEvent *)event
{
	[super mouseUp:event];
	
	[self _resetImage];
}

- (void)setState:(NSControlStateValue)state
{
	[super setState:state];
	
	[self _resetImage];
}

- (void)_resetImage
{
	if(@available(macOS 11.0, *))
	{
		NSImage* nowImage = [NSImage imageWithSystemSymbolName: self.state == NSControlStateValueOn ? @"arrow.up.left.circle.fill" : @"arrow.up.left.circle" accessibilityDescription:nil];
		nowImage.size = CGSizeMake(15, 15);
		self.image = nowImage;
	}
	else
	{
		NSString* imageName = [NSString stringWithFormat:@"NowTemplate%@", self.state == NSControlStateValueOn ? @"On" : @""];
		self.image = [NSImage imageNamed:imageName];
	}
}

@end
