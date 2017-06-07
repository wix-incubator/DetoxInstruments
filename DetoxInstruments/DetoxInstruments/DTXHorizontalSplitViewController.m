//
//  DTXHorizontalSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXHorizontalSplitViewController.h"

@interface DTXHorizontalSplitViewController ()

@end

@implementation DTXHorizontalSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleRightSubviewCollapseNotification:) name:@"toggleRightSubviewCollapse:" object:nil];
	
	self.splitViewItems.lastObject.automaticMaximumThickness = 320;
}

- (void)toggleRightSubviewCollapseNotification:(NSNotification*)notification
{
	self.splitViewItems.lastObject.animator.collapsed = !self.splitViewItems.lastObject.collapsed;
}


@end
