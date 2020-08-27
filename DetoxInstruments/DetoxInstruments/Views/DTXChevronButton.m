//
//  DTXChevronButton.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/27/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXChevronButton.h"
@import QuartzCore;
#import "NSImage+UIAdditions.h"
#import "NSAppearance+UIAdditions.h"

@class _DTXChevronButtonPopUpButton;

@interface NSButtonCell ()

- (BOOL)_shouldDrawAsDefaultButtonInView:(id)arg1;

@end

@interface DTXChevronButton ()

@property (nonatomic, strong) _DTXChevronButtonPopUpButton* popupButton;

@end

@interface _DTXChevronButtonPopUpButton : NSPopUpButton

@property (nonatomic, weak) NSButton* parentButton;
@property (nonatomic) BOOL parentHasDefaultButtonAppearance;

@end

static NSImage* _whiteChevronImage;
static NSImage* _blackChevronImage;

@interface _DTXChevronButtonPopUpButtonCell : NSPopUpButtonCell @end

@implementation _DTXChevronButtonPopUpButtonCell

+ (void)load
{
	@autoreleasepool {
		_whiteChevronImage = [[NSImage imageNamed:@"NSDropDownIndicator"] imageTintedWithColor:NSColor.whiteColor];
		_blackChevronImage = [[NSImage imageNamed:@"NSDropDownIndicator"] imageTintedWithColor:NSColor.blackColor];
	}
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	return NSZeroRect;
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame inView:(_DTXChevronButtonPopUpButton*)controlView
{
	NSImage* menuIndicator = controlView.parentHasDefaultButtonAppearance ? _whiteChevronImage : controlView.effectiveAppearance.isDarkAppearance ? _whiteChevronImage : _blackChevronImage;
	
	CGFloat fraction = 1.0;
	if(self.isEnabled == NO /* || controlView.parentHasDefaultButtonAppearance == NO */)
	{
		fraction = 0.2;
	}
	
	[menuIndicator drawInRect:NSMakeRect(cellFrame.size.width - 12 - menuIndicator.size.width / 2, CGRectGetMidY(cellFrame) - menuIndicator.size.height / 2 - 1, menuIndicator.size.width + 1, menuIndicator.size.height) fromRect:NSMakeRect(0, 0, menuIndicator.size.width, menuIndicator.size.height) operation:NSCompositingOperationDestinationOver fraction:fraction respectFlipped:YES hints:nil];
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	
	[[NSColor.blackColor colorWithAlphaComponent:0.1] set];
	
	CGContextSetLineWidth(ctx, 1.0);
	CGContextSetAllowsAntialiasing(ctx, NO);
	
	CGPoint start = CGPointMake(cellFrame.size.width - 20, 2);
	CGPoint end = CGPointMake(cellFrame.size.width - 20, cellFrame.size.height - 4);
	if(controlView.window.backingScaleFactor > 1.0)
	{
		start.x += 0.5;
		end.x += 0.5;
	}
	
	CGContextMoveToPoint(ctx, start.x, start.y);
	CGContextAddLineToPoint(ctx, end.x, end.y);
	CGContextStrokePath(ctx);
}

- (void)setHighlighted:(BOOL)highlighted
{
	[[(_DTXChevronButtonPopUpButton*)self.controlView parentButton] setHighlighted:highlighted];
}

@end

@implementation _DTXChevronButtonPopUpButton
{
	CGPoint _mouseDownOrigin;
}

+ (Class)cellClass
{
	return _DTXChevronButtonPopUpButtonCell.class;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		_parentHasDefaultButtonAppearance = YES;
	}
	
	return self;
}

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

- (void)setParentHasDefaultButtonAppearance:(BOOL)allowsEnabled
{
	_parentHasDefaultButtonAppearance = allowsEnabled;
	
	[self setNeedsDisplay:YES];
}

@end

@interface DTXChevronButtonCell : NSButtonCell @end
@implementation DTXChevronButtonCell

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	frame = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width - 7, frame.size.height);

	return [super drawTitle:title withFrame:frame inView:controlView];
}

- (BOOL)_shouldDrawAsDefaultButtonInView:(DTXChevronButton*)arg1
{
	BOOL rv = [super _shouldDrawAsDefaultButtonInView:arg1];
	//This mechanism is used to draw the pop up button differently when the enclosing button is not drawn as "default".
	arg1.popupButton.parentHasDefaultButtonAppearance = rv;
	return rv;
}

@end

@implementation DTXChevronButton

+ (Class)cellClass
{
	return DTXChevronButtonCell.class;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.wantsLayer = YES;
	
	_popupButton = [_DTXChevronButtonPopUpButton new];
	_popupButton.parentButton = self;
	
	NSMenu* menu = [self.menu copy];
	NSMenuItem* firstItem = [menu.itemArray.firstObject copy];
	[menu insertItem:firstItem atIndex:0];
	_popupButton.menu = menu;
	_popupButton.pullsDown = YES;
	_popupButton.translatesAutoresizingMaskIntoConstraints = NO;
//	_popupButton.keyEquivalent = self.keyEquivalent;
	_popupButton.wantsLayer = YES;
	[self addSubview:_popupButton];
	
	[NSLayoutConstraint activateConstraints:@[
		[self.trailingAnchor constraintEqualToAnchor:_popupButton.trailingAnchor],
		[self.centerYAnchor constraintEqualToAnchor:_popupButton.centerYAnchor],
		[self.widthAnchor constraintEqualToAnchor:_popupButton.widthAnchor multiplier:1.0],
	]];
}

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	
	_popupButton.enabled = enabled;
}

@end
