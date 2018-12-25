//
//  DTXPlotHostingTableCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPlotHostingTableCellView.h"

@implementation DTXPlotHostingTableCellView

- (void)awakeFromNib
{
	self.wantsLayer = YES;
}

- (void)prepareForReuse
{
	[self.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj removeFromSuperview];
	}];
	
	self.plotController = nil;
	
	[super prepareForReuse];
}

- (void)setPlotController:(id<DTXPlotController>)plotController
{
	_plotController = plotController;
	
	[_plotController setUpWithView:self];
}

- (NSSize)intrinsicContentSize
{
	return NSMakeSize(-1, 80);
}

@end
