//
//  DTXMainBottomPaneSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXMainBottomPaneSplitViewController.h"

@interface DTXMainBottomPaneSplitViewController ()

@end

@implementation DTXMainBottomPaneSplitViewController

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
