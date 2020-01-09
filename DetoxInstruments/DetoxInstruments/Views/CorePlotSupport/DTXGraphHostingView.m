//
//  DTXGraphHostingView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 09/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXGraphHostingView.h"

@implementation DTXGraphHostingView

@synthesize flipped=_flipped;

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if(self)
	{
		self.wantsLayer = YES;
		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
		self.openHandCursor = [NSCursor arrowCursor];
//		self.closedHandCursor = [NSCursor arrowCursor];
	}
	return self;
}

- (void)_scrollPlorRangeWithDelta:(double)delta
{
	if(delta == 0)
	{
		return;
	}
	
	CPTXYPlotSpace* plotSpace = (id)self.hostedGraph.defaultPlotSpace;
	
	CPTMutablePlotRange* xRange = [plotSpace.xRange mutableCopy];
	CGFloat selfWidth = self.bounds.size.width;
	
	double previousLocation = xRange.locationDouble;
	
	double maxLocation = plotSpace.globalXRange.lengthDouble - xRange.lengthDouble;
	
	xRange.locationDouble = MIN(maxLocation, MAX(0, xRange.locationDouble - xRange.lengthDouble * delta / selfWidth));
	
	if(xRange.locationDouble != previousLocation)
	{
		plotSpace.xRange = xRange;
	}
}

-(void)scrollWheel:(nonnull NSEvent *)event
{
	if(fabs(event.scrollingDeltaY) > fabs(event.scrollingDeltaX))
	{
		[self.nextResponder scrollWheel:event];
		return;
	}
	
	[self _scrollPlorRangeWithDelta:event.scrollingDeltaX];
}

@end
