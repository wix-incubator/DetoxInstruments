//
//  DTXTouchBarGraphHostingView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/19/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXTouchBarGraphHostingView.h"

@implementation DTXTouchBarGraphHostingView

- (void)touchesBeganWithEvent:(NSEvent *)event
{
	[super touchesBeganWithEvent:event];

	CPTGraph *theGraph = self.hostedGraph;
	BOOL handled       = NO;

	if(theGraph)
	{
		CGPoint pointOfMouseDown   = NSPointToCGPoint([event.allTouches.anyObject locationInView:self]);
		CGPoint pointInHostedGraph = [self.layer convertPoint:pointOfMouseDown toLayer:theGraph];
		id x = nil;
		handled = [theGraph pointingDeviceDownEvent:x atPoint:pointInHostedGraph];
	}

	if(!handled)
	{
		[self.nextResponder touchesBeganWithEvent:event];
	}

}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
	CPTGraph *theGraph = self.hostedGraph;
	BOOL handled       = NO;

	if(theGraph)
	{
		CGPoint pointOfMouseDrag   = NSPointToCGPoint([event.allTouches.anyObject locationInView:self]);
		CGPoint pointInHostedGraph = [self.layer convertPoint:pointOfMouseDrag toLayer:theGraph];
		id x = nil;
		handled = [theGraph pointingDeviceDraggedEvent:x atPoint:pointInHostedGraph];
	}

	if (!handled)
	{
		[self.nextResponder touchesMovedWithEvent:event];
	}

}

- (void)touchesEndedWithEvent:(NSEvent *)event
{
	CPTGraph *theGraph = self.hostedGraph;
	BOOL handled       = NO;

	if(theGraph)
	{
		CGPoint pointOfMouseUp     = NSPointToCGPoint([event.allTouches.anyObject locationInView:self]);
		CGPoint pointInHostedGraph = [self.layer convertPoint:pointOfMouseUp toLayer:theGraph];
		id x = nil;
		handled = [theGraph pointingDeviceUpEvent:x atPoint:pointInHostedGraph];
	}

	if(!handled)
	{
		[self.nextResponder touchesEndedWithEvent:event];
	}
}

@end
