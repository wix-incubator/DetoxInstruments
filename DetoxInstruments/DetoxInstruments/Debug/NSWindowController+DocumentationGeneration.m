//
//  NSWindowController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan on 10/25/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "NSWindowController+DocumentationGeneration.h"
@import QuartzCore;

@implementation NSWindowController (DocumentationGeneration)

- (void)_drainLayout
{
	[self _drainLayoutWithDuration:0.05];
}

- (void)_drainLayoutWithDuration:(NSTimeInterval)duration
{
	[self.window layoutIfNeeded];
	[CATransaction flush];
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];
	[CATransaction flush];
}

- (void)_setWindowSize:(NSSize)size
{
	[self.window setFrame:(CGRect){0, 0, size} display:YES];
	[self.window center];
	NSOutlineView* timelineView = (NSOutlineView*)[self valueForKeyPath:@"_plotContentController._tableView"];
	[timelineView.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj setNeedsDisplay:YES];
		[obj displayIfNeeded];
	}];
	[self _drainLayout];
}


@end
