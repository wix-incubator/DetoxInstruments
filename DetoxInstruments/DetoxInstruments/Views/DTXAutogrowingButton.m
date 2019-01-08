//
//  DTXAutogrowingButton.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/15/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXAutogrowingButton.h"

@implementation DTXAutogrowingButton
{
	NSTrackingArea* _trackingArea;
}

- (void)mouseEntered:(NSEvent *)event
{
	[super mouseEntered:event];
	
	[self _updateButton:YES];
}

- (void)_updateButton:(BOOL)entered
{
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.allowsImplicitAnimation = YES;
		context.duration = 0.1;
		
		self.animator.imagePosition = entered ? NSNoImage : NSImageOnly;
		self.animator.bordered = entered;
		[self.window layoutIfNeeded];
	} completionHandler:nil];
}

- (void)mouseExited:(NSEvent *)event
{
	[super mouseExited:event];
	
	[self _updateButton:NO];
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	if(_trackingArea != nil)
	{
		[self removeTrackingArea:_trackingArea];
	}
	
	_trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
	[self addTrackingArea:_trackingArea];
}

@end
