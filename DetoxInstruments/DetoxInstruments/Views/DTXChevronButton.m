//
//  DTXChevronButton.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/27/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXChevronButton.h"
@import QuartzCore;
#import "NSAppearance+UIAdditions.h"

@interface NSControl ()

//- (BOOL)_shouldTrackMouseWithEvent:(NSEvent *)event;

@end

@interface _DTXChevronButtonPopUpButton : NSPopUpButton

//@property (nonatomic) BOOL acceptsMouseEvents;

@end

@implementation _DTXChevronButtonPopUpButton
{
	CGPoint _mouseDownOrigin;
}

//- (BOOL)_shouldTrackMouseWithEvent:(NSEvent *)event
//{
//	return self.acceptsMouseEvents && [super _shouldTrackMouseWithEvent:event];
//}

- (void)mouseDown:(NSEvent *)event
{
	_mouseDownOrigin = [self convertPoint:event.locationInWindow fromView:nil];

	if(self.bounds.size.width - _mouseDownOrigin.x < 20)
	{
		[super mouseDown:event];
		return;
	}
	
	[self.nextResponder mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event
{
	if(self.bounds.size.width - _mouseDownOrigin.x < 20)
	{
		[super mouseUp:event];
		return;
	}
	
	[self.nextResponder mouseUp:event];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if(self.window.isKeyWindow == NO || self.enabled == NO)
	{
		self.alphaValue = 0.2;
	}
	else
	{
		self.alphaValue = 1.0;
	}
	
	[super drawRect:dirtyRect];
	
	[[NSColor.blackColor colorWithAlphaComponent:0.1] set];

	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	CGContextSetLineWidth(ctx, 1.0);
	CGContextSetAllowsAntialiasing(ctx, NO);
	CGContextMoveToPoint(ctx, self.bounds.size.width - 20, 1);
	CGContextAddLineToPoint(ctx, self.bounds.size.width - 20, self.bounds.size.height - 3);
	CGContextStrokePath(ctx);
}

@end

@interface DTXChevronButtonCell : NSButtonCell @end
@implementation DTXChevronButtonCell

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	frame = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width - 10, frame.size.height);
	
	return [super drawTitle:title withFrame:frame inView:controlView];
}

@end

@implementation DTXChevronButton
{
	NSImageView* _dropDownImageView;
	NSPopUpButton* _popupButton;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.wantsLayer = YES;
	
//	_dropDownImageView = [NSImageView new];
//	_dropDownImageView.image = [NSImage imageNamed:@"NSDropDownIndicatorTemplate"];
//	_dropDownImageView.translatesAutoresizingMaskIntoConstraints = NO;
//	[self addSubview:_dropDownImageView];
//
//	[NSLayoutConstraint activateConstraints:@[
//		[self.trailingAnchor constraintEqualToAnchor:_dropDownImageView.trailingAnchor constant:6],
//		[self.centerYAnchor constraintEqualToAnchor:_dropDownImageView.centerYAnchor],
//	]];
	
	_popupButton = [_DTXChevronButtonPopUpButton new];
	
	NSMenu* menu = [self.menu copy];
	NSMenuItem* firstItem = [menu.itemArray.firstObject copy];
	[menu insertItem:firstItem atIndex:0];
	_popupButton.menu = menu;
	_popupButton.pullsDown = YES;
	_popupButton.translatesAutoresizingMaskIntoConstraints = NO;
	_popupButton.keyEquivalent = self.keyEquivalent;
	_popupButton.wantsLayer = YES;
	[self addSubview:_popupButton];
	
	[NSLayoutConstraint activateConstraints:@[
		[self.trailingAnchor constraintEqualToAnchor:_popupButton.trailingAnchor],
		[self.centerYAnchor constraintEqualToAnchor:_popupButton.centerYAnchor],
		[self.widthAnchor constraintEqualToAnchor:_popupButton.widthAnchor multiplier:1.0],
	]];
}

- (void)layout
{
	[super layout];
	
	CAShapeLayer* mask = CAShapeLayer.layer;
	CGPathRef path = CGPathCreateWithRect(CGRectMake(_popupButton.bounds.size.width - 20, 0, 20, _popupButton.bounds.size.height), NULL);
	mask.path = path;
	CGPathRelease(path);
	
	_popupButton.layer.mask = mask;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//	BOOL isActive = self.window.isKeyWindow;
//	BOOL isDark = self.effectiveAppearance.isDarkAppearance;
//	BOOL isEnabled = self.isEnabled;
//
//	_dropDownImageView.contentTintColor = isEnabled == NO ? NSColor.disabledControlTextColor : isDark || isActive ? NSColor.whiteColor : NSColor.blackColor;
//
//	[super drawRect:dirtyRect];
//}

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	
	_popupButton.enabled = enabled;
}

@end
