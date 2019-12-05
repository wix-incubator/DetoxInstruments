//
//  DTXWindowsSnapshotter.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/13/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXWindowsSnapshotter.h"
@import UIKit;

#if ! TARGET_OS_MACCATALYST
@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;
- (id)_visibleWindows;

@end

@interface UIWindow ()

+ (id)allWindowsIncludingInternalWindows:(_Bool)arg1 onlyVisibleWindows:(_Bool)arg2 forScreen:(id)arg3;

@end
#else
@interface NSObject ()

+ (nullable NSArray<NSNumber *> *)windowNumbersWithOptions:(NSUInteger)options;

@end
#endif

@implementation DTXWindowsSnapshotter

#if ! TARGET_OS_MACCATALYST
+ (NSArray<UIWindow*>*)_uikitWindowList
{
	if(@available(iOS 13, *))
	{
		return UIWindowScene._keyWindowScene._visibleWindows;
	}
	else
	{
		return [UIWindow allWindowsIncludingInternalWindows:YES onlyVisibleWindows:YES forScreen:UIScreen.mainScreen];
	}
}

+ (UIImage*)_uikitSnapshot
{
//	UIView* snapshotView = [UIScreen.mainScreen snapshotViewAfterScreenUpdates:NO];
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	CGSize imageSize = UIScreen.mainScreen.fixedCoordinateSpace.bounds.size;
	
	UIGraphicsBeginImageContextWithOptions(imageSize, NO, UIScreen.mainScreen.scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(context, UIColor.blackColor.CGColor);
	CGContextFillRect(context, (CGRect){0,0, imageSize});
	
	NSArray* windows = [self _uikitWindowList];
	for (UIWindow *window in windows)
	{
		CGContextSaveGState(context);
		CGContextTranslateCTM(context, window.center.x, window.center.y);
		CGContextConcatCTM(context, window.transform);
		CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
		
		if (orientation == UIInterfaceOrientationLandscapeLeft)
		{
			CGContextRotateCTM(context, M_PI_2);
			CGContextTranslateCTM(context, 0, -imageSize.width);
		} else if (orientation == UIInterfaceOrientationLandscapeRight)
		{
			CGContextRotateCTM(context, -M_PI_2);
			CGContextTranslateCTM(context, -imageSize.height, 0);
		} else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
		{
			CGContextRotateCTM(context, M_PI);
			CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
		}
		
		[window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
		CGContextRestoreGState(context);
	}
	
	UIImage* snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return snapshotImage;
}
#else
+ (UIImage*)_appkitSnapshot
{
	CFMutableArrayRef windowIDs = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, NULL);
	NSArray<NSNumber*>* windowNumbers = [NSClassFromString(@"NSWindow") windowNumbersWithOptions:(1 << 0)];
	
	[windowNumbers enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		CFArrayAppendValue(windowIDs, (void*)obj.unsignedIntegerValue);
	}];
	
	CGImageRef windowImage = CGWindowListCreateImageFromArray([[NSClassFromString(@"NSScreen") valueForKeyPath:@"mainScreen.frame"] CGRectValue], windowIDs, kCGWindowImageBestResolution);
	UIImage* rv = [[UIImage alloc] initWithCGImage:windowImage];
	CGImageRelease(windowImage);
	
	return rv;
}
#endif

+ (NSData*)snapshotDataForApp
{
#if ! TARGET_OS_MACCATALYST
	UIImage* image = [self _uikitSnapshot];
	return UIImagePNGRepresentation(image);
#else
	UIImage* image = [self _appkitSnapshot];
	return UIImagePNGRepresentation(image);
#endif
}

@end
