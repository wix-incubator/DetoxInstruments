//
//  DTXManagedPlotControllerGroup.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 02/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXManagedPlotControllerGroup.h"
#import "DTXTimelineIndicatorView.h"

@interface DTXManagedPlotControllerGroup () <DTXPlotControllerDelegate>
{
	NSMutableArray<id<DTXPlotController>>* _managedPlotControllers;
	
	BOOL _ignoringPlotRangeNotifications;
	DTXTimelineIndicatorView* _timelineView;
	CPTPlotRange* _savedPlotRange;
	CPTPlotRange* _savedGlobalPlotRange;
}

@end

@implementation DTXManagedPlotControllerGroup

- (instancetype)initWithHostingView:(NSView*)view
{
	self = [super init];
	
	if(self)
	{
		_managedPlotControllers = [NSMutableArray new];
		_hostingView = view;
		
		_timelineView = [DTXTimelineIndicatorView new];
		_timelineView.translatesAutoresizingMaskIntoConstraints = NO;
		
		NSTrackingArea* tracker = [[NSTrackingArea alloc] initWithRect:_timelineView.bounds options:NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved owner:self userInfo:nil];
		[_timelineView addTrackingArea:tracker];
		
		[_hostingView addSubview:_timelineView positioned:NSWindowAbove relativeTo:_hostingView.superview];
		
		[NSLayoutConstraint activateConstraints:@[[view.topAnchor constraintEqualToAnchor:_timelineView.topAnchor],
												  [view.leadingAnchor constraintEqualToAnchor:_timelineView.leadingAnchor],
												  [view.trailingAnchor constraintEqualToAnchor:_timelineView.trailingAnchor],
												  [view.bottomAnchor constraintEqualToAnchor:_timelineView.bottomAnchor]]];
	}
	
	return self;
}

- (NSArray<id<DTXPlotController>> *)plotControllers
{
	return _managedPlotControllers;
}

- (void)addHeaderPlotController:(id<DTXPlotController>)headerPlotController
{
	_headerPlotController = headerPlotController;
	_headerPlotController.delegate = self;
	
	if(_savedGlobalPlotRange)
	{
		[headerPlotController setGlobalPlotRange:_savedGlobalPlotRange enforceOnLocalPlotRange:YES];
	}
	else if(_savedPlotRange)
	{
		[headerPlotController setPlotRange:_savedPlotRange];
	}
}

- (void)addPlotController:(id<DTXPlotController>)plotController
{
	[self insertPlotController:plotController afterPlotController:_managedPlotControllers.lastObject];
}

- (void)removePlotController:(id<DTXPlotController>)plotController
{
	plotController.delegate = nil;
	[_managedPlotControllers removeObject:plotController];
}

- (void)insertPlotController:(id<DTXPlotController>)plotController afterPlotController:(id<DTXPlotController>)afterPlotController
{
	NSUInteger idx;
	
	if(afterPlotController == nil)
	{
		idx = -1;
	}
	else
	{
		idx = [_managedPlotControllers indexOfObject:afterPlotController];
		
		if(idx == NSNotFound)
		{
			return;
		}
	}
	
	[_managedPlotControllers insertObject:plotController atIndex:idx + 1];
	plotController.delegate = self;
	if(_savedGlobalPlotRange)
	{
		[plotController setGlobalPlotRange:_savedGlobalPlotRange enforceOnLocalPlotRange:YES];
	}
	else if(_savedPlotRange)
	{
		[plotController setPlotRange:_savedPlotRange];
	}
}

- (void)mouseEntered:(NSEvent *)event
{
	[self mouseMoved:event];
}

- (void)mouseExited:(NSEvent *)event
{
	_timelineView.displaysIndicator = NO;
}

- (void)mouseMoved:(NSEvent *)event
{
	CGPoint pointInView = [_hostingView convertPoint:[event locationInWindow] fromView:nil];
	
	_timelineView.displaysIndicator = pointInView.x >= 210;
	_timelineView.indicatorOffset = pointInView.x;
}

- (void)setStartTimestamp:(NSDate*)startTimestamp endTimestamp:(NSDate*)endTimestamp;
{
	_savedGlobalPlotRange = [CPTPlotRange plotRangeWithLocation:@0 length:@(endTimestamp.timeIntervalSinceReferenceDate - startTimestamp.timeIntervalSinceReferenceDate)];
	
	BOOL shouldEnforce = _savedPlotRange == nil || fabs(_savedPlotRange.length.doubleValue - _savedGlobalPlotRange.length.doubleValue) < 1;
	
	_ignoringPlotRangeNotifications = YES;
	[_headerPlotController setGlobalPlotRange:_savedGlobalPlotRange enforceOnLocalPlotRange:shouldEnforce];
	[_managedPlotControllers enumerateObjectsUsingBlock:^(id<DTXPlotController>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj setGlobalPlotRange:_savedGlobalPlotRange enforceOnLocalPlotRange:shouldEnforce];
	}];
	if(shouldEnforce)
	{
		_savedPlotRange = nil;
	}
	_ignoringPlotRangeNotifications = NO;
}

- (void)zoomIn
{
	//Zooming in or out one plot controller will propagate to others using the plotController:didChangeToPlotRange: delegate method.
	[_managedPlotControllers.firstObject zoomIn];
}

- (void)zoomOut
{
	//Zooming in or out one plot controller will propagate to others using the plotController:didChangeToPlotRange: delegate method.
	[_managedPlotControllers.firstObject zoomOut];
}

#pragma mark DTXPlotControllerDelegate

//TODO: Fix
static BOOL __uglyHackTODOFixThisShit()
{
	return [[[NSThread callStackSymbols] description] containsString:@"CPTAnimation"];
}

- (void)plotController:(id<DTXPlotController>)pc didChangeToPlotRange:(CPTPlotRange *)plotRange
{
	if(_ignoringPlotRangeNotifications || __uglyHackTODOFixThisShit())
	{
		return;
	}
	
	_ignoringPlotRangeNotifications = YES;
	_savedPlotRange = plotRange;
	
	if(pc != _headerPlotController)
	{
		[_headerPlotController setPlotRange:plotRange];
	}
	
	[_managedPlotControllers enumerateObjectsUsingBlock:^(id<DTXPlotController>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj == pc)
		{
			return;
		}
		
		[obj setPlotRange:plotRange];
	}];
	
	_ignoringPlotRangeNotifications = NO;
}

- (void)plotControllerUserDidClickInPlotBounds:(id<DTXPlotController>)pc
{
	[self.delegate managedPlotControllerGroup:self requestPlotControllerSelection:pc];
}

- (void)requiredHeightChangedForPlotController:(id<DTXPlotController>)pc
{
	[self.delegate managedPlotControllerGroup:self requiredHeightChangedForPlotController:pc index:[_managedPlotControllers indexOfObject:pc]];
}

@end
