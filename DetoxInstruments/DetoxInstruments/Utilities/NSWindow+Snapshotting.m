//
//  NSWindow+Snapshotting.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSWindow+Snapshotting.h"
#import "NSView+UIAdditions.h"
@import ObjectiveC;
@import QuartzCore;

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

- (void)transitionToAppearance:(NSAppearance *)appearance
{
	NSView* themeFrame = [self valueForKey:@"themeFrame"];
	
	NSImage* snapshot = [themeFrame snapshotForCachingDisplay];
	NSImageView* snapshotView = [NSImageView imageViewWithImage:snapshot];
	snapshotView.wantsLayer = YES;
	snapshotView.frame = themeFrame.frame;
	
	self.appearance = appearance; 
	
	struct objc_super superInfo = {
		themeFrame,
		themeFrame.superclass
	};
	
	void (*msgSuper)(struct objc_super *, SEL, id) = (void*)objc_msgSendSuper;
	
	msgSuper(&superInfo, @selector(addSubview:), snapshotView);
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.2;
		context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		context.allowsImplicitAnimation = YES;
		snapshotView.animator.alphaValue = 0.0;
	} completionHandler:^{
		[snapshotView removeFromSuperview];
	}];
}

@end
