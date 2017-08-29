//
//  DTXBaseSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXBaseSplitViewController.h"

IB_DESIGNABLE
@interface DTXBorderedView : NSView @end

@implementation DTXBorderedView

- (void)awakeFromNib
{
	[super awakeFromNib];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	[NSColor.controlShadowColor set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint(self.bounds.size.width, 0)];
}

@end

IB_DESIGNABLE
@interface _DTXSplitView : NSSplitView @end

@implementation _DTXSplitView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
}

- (NSColor *)dividerColor
{
	const CGFloat grey = 188.0 / 255.0;
	return [NSColor colorWithSRGBRed:grey green:grey blue:grey alpha:1.0];
}

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
	
	self.splitViewItems.lastObject.minimumThickness = [self lastSplitItemMinThickness];
	self.splitViewItems.lastObject.maximumThickness = [self lastSplitItemMaxThickness];
	self.splitViewItems.lastObject.canCollapse = YES;
	self.splitViewItems.lastObject.collapseBehavior = NSSplitViewItemCollapseBehaviorUseConstraints;
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	self.splitViewItems.lastObject.minimumThickness = [self lastSplitItemMinThickness];
	self.splitViewItems.lastObject.maximumThickness = [self lastSplitItemMaxThickness];
}


@end
