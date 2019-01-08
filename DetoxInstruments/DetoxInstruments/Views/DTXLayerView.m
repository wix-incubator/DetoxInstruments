//
//  DTXLayerView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXLayerView.h"

@implementation DTXLayerView
{
	__weak NSAppearance* _cachedAppearance;
	CGFloat _cachedBackingScaleFactor;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	
	if(self)
	{
		[self _setupLayer];
	}
	
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		[self _setupLayer];
	}
	
	return self;
}

- (void)_setupLayer
{
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)removeFromSuperview
{
	[super removeFromSuperview];
}

- (void)updateLayer
{
	[super updateLayer];
	
	if(self.effectiveAppearance != _cachedAppearance || _cachedBackingScaleFactor != self.window.screen.backingScaleFactor)
	{
		if(self.updateLayerHandler)
		{
			self.updateLayerHandler(self);
		}
		
		_cachedAppearance = self.effectiveAppearance;
		_cachedBackingScaleFactor = self.window.screen.backingScaleFactor;
	}
}

@end
