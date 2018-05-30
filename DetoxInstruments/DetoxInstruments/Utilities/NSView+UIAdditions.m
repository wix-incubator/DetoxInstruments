//
//  NSView+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSView+UIAdditions.h"

@implementation NSView (UIAdditions)

- (NSImage*)snapshotForCachingDisplay
{
	NSBitmapImageRep* rep = [self bitmapImageRepForCachingDisplayInRect:self.bounds];
	[self cacheDisplayInRect:self.bounds toBitmapImageRep:rep];
	
	NSImage* image = [[NSImage alloc] initWithSize:self.bounds.size];
	[image addRepresentation:rep];
	
	return image;
}

- (void)scrollToBottom
{
	[self scrollPoint:NSMakePoint(0, NSHeight(self.bounds))];
}

@end
