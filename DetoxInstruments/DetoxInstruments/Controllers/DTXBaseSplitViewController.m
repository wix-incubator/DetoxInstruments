//
//  DTXBaseSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXBaseSplitViewController.h"
#import "NSAppearance+UIAdditions.h"

@interface DTXBorderedView : NSBox @end

@implementation DTXBorderedView
{
	CALayer* _lineLayer;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.boxType = NSBoxCustom;
	self.cornerRadius = 0.0;
	self.fillColor = NSColor.windowBackgroundColor;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	self.wantsLayer = YES;
	
	_lineLayer = [CALayer new];
	_lineLayer.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
	_lineLayer.autoresizingMask = kCALayerWidthSizable;
	_lineLayer.zPosition = 10;
	
	[self.layer addSublayer:_lineLayer];
}

- (void)updateLayer
{
	_lineLayer.backgroundColor = self.effectiveAppearance.isDarkAppearance ? NSColor.blackColor.CGColor : NSColor.quaternaryLabelColor.CGColor;
}

@end

@interface _DTXSplitView : NSSplitView @end

@implementation _DTXSplitView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

//- (NSColor *)dividerColor
//{
//	const CGFloat grey = 188.0 / 255.0;
//	return [NSColor colorWithSRGBRed:grey green:grey blue:grey alpha:1.0];
//}

@end

@interface DTXBaseSplitViewController ()

@end

@implementation DTXBaseSplitViewController

- (CGFloat)lastSplitItemMaxThickness
{
	return NSSplitViewItemUnspecifiedDimension;
}

- (CGFloat)lastSplitItemMinThickness
{
	return 320;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	self.splitViewItems.lastObject.minimumThickness = [self lastSplitItemMinThickness];
	self.splitViewItems.lastObject.maximumThickness = [self lastSplitItemMaxThickness];
	self.splitViewItems.lastObject.canCollapse = YES;
	self.splitViewItems.lastObject.collapseBehavior = NSSplitViewItemCollapseBehaviorPreferResizingSiblingsWithFixedSplitView;
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	self.splitViewItems.lastObject.minimumThickness = [self lastSplitItemMinThickness];
	self.splitViewItems.lastObject.maximumThickness = [self lastSplitItemMaxThickness];
}


@end
