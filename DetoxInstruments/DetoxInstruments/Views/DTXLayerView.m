//
//  DTXLayerView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXLayerView.h"

@implementation DTXLayerView
{
	__weak NSAppearance* _cachedAppearance;
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

- (void)updateLayer
{
	[super updateLayer];
	
	if(self.effectiveAppearance != _cachedAppearance)
	{
		if(self.updateLayerHandler)
		{
			self.updateLayerHandler(self);
		}
		
		_cachedAppearance = self.effectiveAppearance;
	}
}

@end
