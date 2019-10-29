//
//  DTXOutlineDetailController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXOutlineDetailController.h"

@implementation DTXOutlineDetailController
{
	IBOutlet NSOutlineView* _outlineView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	_outlineView.wantsLayer = YES;
	_outlineView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	self.detailDataProvider.managedOutlineView = _outlineView;
}

- (void)setDetailDataProvider:(DTXDetailDataProvider *)detailDataProvider
{
	if(super.detailDataProvider != nil)
	{
		super.detailDataProvider.managedOutlineView = nil;
	}
	super.detailDataProvider = detailDataProvider;
	super.detailDataProvider.managedOutlineView = _outlineView;
}

- (void)viewDidLayout
{
	[super viewDidLayout];
	
	if(_outlineView.tableColumns.lastObject.resizingMask != NSTableColumnAutoresizingMask)
	{
		return;
	}
	
	[_outlineView sizeLastColumnToFit];
}

- (void)updateViewWithInsets:(NSEdgeInsets)insets
{
	_outlineView.enclosingScrollView.contentInsets = insets;
}

@end
