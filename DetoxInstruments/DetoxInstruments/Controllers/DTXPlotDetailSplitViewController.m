//
//  DTXPlotDetailSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPlotDetailSplitViewController.h"

@interface DTXPlotDetailSplitViewController ()

@end

@implementation DTXPlotDetailSplitViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.splitViewItems.lastObject.automaticMaximumThickness = 320;
}

- (CGFloat)lastSplitItemMaxThickness
{
	return NSSplitViewItemUnspecifiedDimension;
}

- (CGFloat)lastSplitItemMinThickness
{
	return self.view.window == nil ? 320 : 88;
}

@end
