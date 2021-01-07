//
//  DTXDetailInspectorSplitViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXDetailInspectorSplitViewController.h"
#import "DTXInspectorContentController.h"

@interface DTXDetailInspectorSplitViewController ()

@end

@implementation DTXDetailInspectorSplitViewController
{
	DTXInspectorContentController* _inspectorContentController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_inspectorContentController = (id)self.splitViewItems.lastObject.viewController;
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

- (BOOL)expandPreview
{
	return [_inspectorContentController expandPreview];
}

@end

