//
//  NSView+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "NSView+UIAdditions.h"

@implementation NSView (UIAdditions)

- (NSImage*)snapshotForCachingDisplay
{
	CGRect rect = self.bounds; //CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(2.0, 2.0));
	
	NSBitmapImageRep* rep = [self bitmapImageRepForCachingDisplayInRect:rect];
	[self cacheDisplayInRect:rect toBitmapImageRep:rep];
	
	NSImage* image = [[NSImage alloc] initWithSize:rect.size];
	[image addRepresentation:rep];
	
	return image;
}

- (void)scrollToBottom
{
	[self scrollPoint:NSMakePoint(0, NSHeight(self.bounds))];
}

@end
