//
//  DTXPlotTableView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 02/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPlotTableView.h"

@interface _DTXEventWrapper : NSObject @end
@implementation _DTXEventWrapper
{
	NSEvent* _obj;
	NSView* _view;
}

- (instancetype)initWithEvent:(NSEvent*)event fakedCoordsOfView:(NSView*)view
{
	self = [super init];
	_obj = event;
	_view = view;
	return self;
}

- (NSPoint)locationInWindow
{
	NSPoint pt = [_obj locationInWindow];
	NSRect frameInWin = [_view convertRect:_view.bounds toView:nil];
	
	pt.y = frameInWin.origin.y + 1;
	if(pt.x < frameInWin.origin.x)
	{
		pt.x = frameInWin.origin.x;
	}
	
	return pt;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [_obj methodSignatureForSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return _obj;
}

@end

IB_DESIGNABLE
@implementation DTXPlotTableView
{
	BOOL _ignoresEvents;
}

- (void)drawGridInClipRect:(NSRect)clipRect
{
	NSRect lastRowRect = [self rectOfRow:[self numberOfRows] - 1];
	NSRect myClipRect = NSMakeRect(0, 0, lastRowRect.size.width, NSMaxY(lastRowRect));
	NSRect finalClipRect = NSIntersectionRect(clipRect, myClipRect);
	[super drawGridInClipRect:finalClipRect];
}

-(void)magnifyWithEvent:(nonnull NSEvent *)event
{
	if(_ignoresEvents)
	{
		return;
	}
	
	_ignoresEvents = YES;
	NSTableRowView* rowView = [self rowViewAtRow:0 makeIfNecessary:NO];
	NSView* actualView = [[[rowView viewAtColumn:rowView.numberOfColumns - 1] subviews] lastObject];
	
	[actualView magnifyWithEvent:(id)[[_DTXEventWrapper alloc] initWithEvent:event fakedCoordsOfView:actualView]];
	_ignoresEvents = NO;
}

- (void)scrollWheel:(NSEvent *)event
{
	if(_ignoresEvents)
	{
		return;
	}
	
	_ignoresEvents = YES;
	if(fabs(event.scrollingDeltaY) >= fabs(event.scrollingDeltaX))
	{
		[super scrollWheel:event];
		_ignoresEvents = NO;
		return;
	}
	
	NSTableRowView* rowView = [self rowViewAtRow:0 makeIfNecessary:NO];
	NSView* actualView = [[[rowView viewAtColumn:rowView.numberOfColumns - 1] subviews] lastObject];
	
	[actualView scrollWheel:(id)[[_DTXEventWrapper alloc] initWithEvent:event fakedCoordsOfView:actualView]];
	_ignoresEvents = NO;
}

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
	// This allows the user to click on controls within a cell withough first having to select the cell row
	return YES;
}

@end
