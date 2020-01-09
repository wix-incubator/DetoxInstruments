//
//  DTXPlotStackView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/31/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXPlotStackView.h"
#import "DTXScatterPlotView-Private.h"

@interface DTXPlotStackView () <DTXPlotHeightSynchronization>

@end

@implementation DTXPlotStackView

@synthesize maximumPlotHeight=_maximumPlotHeight;

- (void)insertArrangedSubview:(NSView *)view atIndex:(NSInteger)index
{
	[super insertArrangedSubview:view atIndex:index];
	
	if([view isKindOfClass:DTXScatterPlotView.class])
	{
		DTXScatterPlotView* scatterPlotView = (id)view;
		scatterPlotView.heightSynchronizer = self;
	}
}

- (void)removeArrangedSubview:(NSView *)view
{
	[super removeArrangedSubview:view];
	
	if([view isKindOfClass:DTXScatterPlotView.class])
	{
		DTXScatterPlotView* scatterPlotView = (id)view;
		scatterPlotView.heightSynchronizer = nil;
	}
}

- (NSView *)hitTest:(NSPoint)point
{
	NSView* rv = [super hitTest:point];
	
	if(rv == self)
	{
		return self.arrangedSubviews.firstObject;
	}
	
	return rv;
}

@end
