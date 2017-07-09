//
//  DTXBottomInspectorSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXBottomInspectorSplitViewController.h"

@interface DTXBottomInspectorSplitViewController ()

@end

@implementation DTXBottomInspectorSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.splitViewItems.lastObject.automaticMaximumThickness = 320;
	self.splitViewItems.lastObject.holdingPriority = NSLayoutPriorityDefaultLow;
}

- (CGFloat)lastSplitItemMaxThickness
{
	return CGFLOAT_MAX;
}

@end

