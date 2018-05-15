//
//  NSWindow+Snapshotting.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSWindow+Snapshotting.h"

@implementation NSWindow (Snapshotting)

- (CGFloat)_titlebarHeight
{
	return self.frame.size.height - self.contentLayoutRect.size.height;
}

- (NSImage*)snapshotForCachingDisplay
{
	CFMutableArrayRef windowIDs = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, NULL);
	NSArray<NSNumber*>* windowNumbers = [NSWindow windowNumbersWithOptions:0];
	NSUInteger indexOfMe = [windowNumbers indexOfObject:@(self.windowNumber)];
	
	[windowNumbers enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(idx > indexOfMe || [NSApp windowWithWindowNumber:obj.integerValue] == nil)
		{
			return;
		}
		
		CFArrayAppendValue(windowIDs, (void*)obj.unsignedIntegerValue);
	}];
	
	NSLog(@"%@", CGWindowListCreateDescriptionFromArray(windowIDs));
	
	CGImageRef windowImage = CGWindowListCreateImageFromArray(CGRectNull, windowIDs, kCGWindowImageDefault);
	NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithCGImage:windowImage];
	CGImageRelease(windowImage);
	
	NSImage * image = [[NSImage alloc] initWithSize:NSMakeSize(CGImageGetWidth(windowImage), CGImageGetHeight(windowImage))];
	[image addRepresentation:rep];
	
	return image;
}

@end
