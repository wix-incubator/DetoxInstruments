//
//  DTXChevronButton.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/27/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXChevronButton.h"
@import QuartzCore;
#import "NSAppearance+UIAdditions.h"

@class _DTXChevronButtonPopUpButton;

@interface NSControl () @end
@interface NSButtonCell ()

- (BOOL)_shouldDrawAsDefaultButtonInView:(id)arg1;
- (NSDictionary*)_coreUIBezelDrawOptionsWithFrame:(struct CGRect)arg1 inView:(id)arg2;

@end

@interface DTXChevronButton ()

@property (nonatomic, strong) _DTXChevronButtonPopUpButton* popupButton;

@end

@interface _DTXChevronButtonPopUpButton : NSPopUpButton

@property (nonatomic) BOOL allowsEnabled;
@property (nonatomic) BOOL userEnabled;

@end

@interface _DTXChevronButtonPopUpButtonCell : NSPopUpButtonCell @end

@implementation _DTXChevronButtonPopUpButtonCell

- (NSDictionary*)_coreUIBezelDrawOptionsWithFrame:(struct CGRect)arg1 inView:(id)arg2
{
	NSMutableDictionary* rv = [[super _coreUIBezelDrawOptionsWithFrame:arg1 inView:arg2] mutableCopy];
	
	return rv;
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
		_allowsEnabled = YES;
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

- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	
	CGContextSaveGState(ctx);
	CGContextSetAlpha(ctx, self.userEnabled ? 1.0 : 0.35);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, CGRectMake(self.bounds.size.width - 20, 2, 15, self.bounds.size.height - 6));
	CGPathAddRect(path, NULL, CGRectMake(self.bounds.size.width - 20, 2.5, 15.5, self.bounds.size.height - 7));
	CGPathAddRect(path, NULL, CGRectMake(self.bounds.size.width - 20, 3, 16, self.bounds.size.height - 8));
	CGContextAddPath(ctx, path);
	CGContextClip(ctx);
	
	[super drawRect:dirtyRect];
	
	CGContextRestoreGState(ctx);
	
	[[NSColor.blackColor colorWithAlphaComponent:0.1] set];

	CGContextSetLineWidth(ctx, 1.0);
	CGContextSetAllowsAntialiasing(ctx, NO);
	
	CGPoint start = CGPointMake(self.bounds.size.width - 20, 2);
	CGPoint end = CGPointMake(self.bounds.size.width - 20, self.bounds.size.height - 4);
	if(self.window.backingScaleFactor > 1.0)
	{
		start.x += 0.5;
		end.x += 0.5;
	}
	
	CGContextMoveToPoint(ctx, start.x, start.y);
	CGContextAddLineToPoint(ctx, end.x, end.y);
	CGContextStrokePath(ctx);
	
	CGPathRelease(path);
}

- (void)setEnabled:(BOOL)enabled
{
	_userEnabled = enabled;
	
	[self _resetEnabled];
	
	[self setNeedsDisplay:YES];
}

- (void)setAllowsEnabled:(BOOL)allowsEnabled
{
	_allowsEnabled = allowsEnabled;
	
	[self _resetEnabled];
}

- (void)_resetEnabled
{
	[super setEnabled:_userEnabled && _allowsEnabled];
}

- (void)layout
{
	[super layout];
}

@end

@interface DTXChevronButtonCell : NSButtonCell @end
@implementation DTXChevronButtonCell

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	frame = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width - 10, frame.size.height);
	
	return [super drawTitle:title withFrame:frame inView:controlView];
}

- (BOOL)_shouldDrawAsDefaultButtonInView:(DTXChevronButton*)arg1
{
	BOOL rv = [super _shouldDrawAsDefaultButtonInView:arg1];
	//This mechanism is used to draw the pop up button differently when the enclosing button is not drawn as "default".
	arg1.popupButton.allowsEnabled = rv;
	return rv;
}

@end

@implementation DTXChevronButton

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.wantsLayer = YES;
	
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

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	
	_popupButton.enabled = enabled;
}

@end
