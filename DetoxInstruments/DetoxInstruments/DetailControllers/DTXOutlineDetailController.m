//
//  DTXOutlineDetailController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXOutlineDetailController.h"

@interface AAA : NSTableCellView @end

@implementation AAA

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	[super viewWillMoveToWindow:newWindow];
}

@end

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
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Samples", @"");
}

- (NSImage *)smallDisplayIcon
{
	NSImage* image = [NSImage imageNamed:@"samples"];
	image.size = NSMakeSize(16, 16);
	
	return image;
}

- (void)setDetailDataProvider:(DTXDetailDataProvider *)detailDataProvider
{
	super.detailDataProvider = detailDataProvider;
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	self.detailDataProvider.managedOutlineView = _outlineView;
}

- (void)viewDidLayout
{
	[super viewDidLayout];
	
	NSTableColumn* lastColumn = _outlineView.tableColumns.lastObject;
	
	if(lastColumn.resizingMask != NSTableColumnAutoresizingMask)
	{
		return;
	}
	
	__block CGFloat bestWidth = _outlineView.bounds.size.width;
	[_outlineView.tableColumns enumerateObjectsUsingBlock:^(NSTableColumn * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj == lastColumn)
		{
			return;
		}
		
		bestWidth -= (obj.width + _outlineView.intercellSpacing.width);
	}];
	lastColumn.width = bestWidth - _outlineView.intercellSpacing.width;
}

- (void)updateViewWithInsets:(NSEdgeInsets)insets
{
	_outlineView.enclosingScrollView.contentInsets = insets;
}

- (NSView *)viewForCopy
{
	return _outlineView;
}

@end
