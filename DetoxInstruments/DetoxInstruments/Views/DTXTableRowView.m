//
//  DTXTableRowView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXTableRowView.h"
#import "NSColor+UIAdditions.h"
#import "NSImage+UIAdditions.h"
#import "NSAppearance+UIAdditions.h"

@interface NSTableRowView ()

- (NSColor*)primarySelectionColor;
- (NSColor*)secondarySelectedControlColor;

@end

@implementation DTXTableRowView
{
	NSImageView* _statusImageView;
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		self.wantsLayer = YES;
		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
//		self.canDrawSubviewsIntoLayer = YES;
		
		_statusImageView = [NSImageView new];
		_statusImageView.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_statusImageView];
		
		CGFloat leadingConstant = 10;
		if(@available(macOS 11.0, *))
		{
			leadingConstant = 14;
		}
		
		[NSLayoutConstraint activateConstraints:@[
												  [_statusImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:leadingConstant],
												  [_statusImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
												  [_statusImageView.widthAnchor constraintEqualToConstant:9],
												  [_statusImageView.heightAnchor constraintEqualToConstant:9],
												  ]];
		
		_statusImageView.wantsLayer = YES;
		_statusImageView.layer.cornerRadius = 4.5;
		_statusImageView.layer.masksToBounds = YES;
		
		_statusImageView.hidden = YES;
	}
	
	return self;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	[super updateLayer];
	
	_statusImageView.layer.backgroundColor = [_userNotifyColor blendedColorWithFraction:0.4 ofColor:NSColor.controlBackgroundColor].CGColor;
}

- (NSColor*)selectionColor
{
	if(self.isEmphasized)
	{
		return self.primarySelectionColor;
	}

	return self.secondarySelectedControlColor;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	[self.selectionColor setFill];

	[[NSBezierPath bezierPathWithRect:dirtyRect] fill];
}

- (void)setUserNotifyTooltip:(NSString*)tooltip
{
	_statusImageView.toolTip = tooltip;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
}

- (BOOL)_isUserNotifyColorImportant
{
	return _userNotifyColor != nil && (_userNotifyColor.type != NSColorTypeCatalog || [_userNotifyColor.colorNameComponent isEqualToString:@"controlBackgroundColor"] == NO);
}

- (void)setUserNotifyColor:(NSColor *)userNotifyColor
{
	_userNotifyColor = userNotifyColor;
	
	if(self._isUserNotifyColorImportant)
	{
		_statusImageView.image = [[NSImage imageNamed:@"statusIcon"] imageTintedWithColor:_userNotifyColor];
		_statusImageView.hidden = NO;
	}
	else
	{
		_statusImageView.image = nil;
		_statusImageView.hidden = YES;
	}
	
	[self setNeedsDisplay:YES];
}

- (void)layout
{
	[super layout];
	
	if(self.isGroupRowStyle)
	{
		[self.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if([obj isKindOfClass:NSClassFromString(@"NSBannerView")])
			{
				return;
			}
			
			if([obj isKindOfClass:[NSButton class]])
			{
				obj.frame = (CGRect){9, obj.frame.origin.y, obj.frame.size};
			}
			else
			{
				obj.frame = (CGRect){37, obj.frame.origin.y, obj.frame.size};
			}
		}];
	}
}

@end
