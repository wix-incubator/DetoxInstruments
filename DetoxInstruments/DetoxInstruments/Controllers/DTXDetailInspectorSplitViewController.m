//
//  DTXDetailInspectorSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXDetailInspectorSplitViewController.h"

@interface DTXDetailInspectorSplitViewController ()

@end

@implementation DTXDetailInspectorSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.splitViewItems.lastObject.automaticMaximumThickness = 320;
}

- (CGFloat)lastSplitItemMaxThickness
{
	return NSSplitViewItemUnspecifiedDimension;
}

- (CGFloat)lastSplitItemMinThickness
{
	return 320;
}

@end

