//
//  DTXScrollView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXScrollView.h"

@implementation DTXScrollView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawBeforeViewResize;
//	self.layer.contentsScale = 0.25;
}

@end

@implementation DTXClipView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	//	self.layer = [CAScrollLayer layer];
	//	self.wantsLayer = YES;
	//	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawBeforeViewResize;
	//	self.layer.contentsScale = 0.25;
}

@end
