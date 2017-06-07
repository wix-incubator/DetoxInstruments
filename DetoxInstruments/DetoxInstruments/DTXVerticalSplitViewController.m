//
//  DTXVerticalSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXVerticalSplitViewController.h"

@interface DTXVerticalSplitViewController ()

@end

@implementation DTXVerticalSplitViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleBottomSubviewCollapseNotification:) name:@"toggleBottomSubviewCollapse:" object:nil];
}

- (CGFloat)lastSplitItemMaxThickness
{
	return self.view.window.frame.size.height * 0.85;
}

- (CGFloat)lastSplitItemMinThickness
{
	return 88;
}

- (void)toggleBottomSubviewCollapseNotification:(NSNotification*)notification
{
	self.splitViewItems.lastObject.animator.collapsed = !self.splitViewItems.lastObject.collapsed;
}

@end
