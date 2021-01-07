//
//  DTXLogLevelCell.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/31/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXLogLevelCell.h"
#import "DTXLogSample+UIExtensions.h"
#import "NSImage+UIAdditions.h"

@implementation DTXLogLevelCell
{
	NSColor* _color;
	NSColor* _backgroundColor;
	NSImage* _image;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect rect = NSMakeRect(CGRectGetMidX(cellFrame) - _image.size.width / 2, CGRectGetMidY(cellFrame) - _image.size.height / 2, _image.size.width, _image.size.height);
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	//This is here because it needs to be performed on each draw, so that controlBackgroundColor blend is always correct.
	[[_color blendedColorWithFraction:0.4 ofColor:NSColor.controlBackgroundColor] setFill];
	CGContextFillEllipseInRect(ctx, rect);
	
	[_image drawInRect:rect];
}

- (void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
	_color = DTXLogLevelColor([objectValue unsignedIntValue]);
	_image = [[NSImage imageNamed:@"statusIcon"] imageTintedWithColor:_color];
}

@end
