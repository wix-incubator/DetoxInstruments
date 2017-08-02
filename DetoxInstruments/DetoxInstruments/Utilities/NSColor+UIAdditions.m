//
//  NSColor+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSColor+UIAdditions.h"

@implementation NSColor (UIAdditions)

+ (NSColor *)warningColor
{
	static NSColor* warningColor;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
//		warningColor = [NSColor colorWithRed:245.0 / 255.0 green:215.0 / 255.0 blue:110.0 / 255.0 alpha:0.25];
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
		warningColor = NSColor.systemYellowColor;
#else
		warningColor = NSColor.yellowColor;
#endif
	});
	return warningColor;
}

+ (NSColor *)warning2Color
{
	static NSColor* warning2Color;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
//		warning2Color = [NSColor colorWithRed:244.0 / 255.0 green:108.0 / 255.0 blue:63.0 / 255.0 alpha:0.25];
		
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
		warning2Color = NSColor.systemOrangeColor;
#else
		warning2Color = NSColor.orangeColor;
#endif
	});
	return warning2Color;
}

+ (NSColor *)warning3Color
{
	static NSColor* warning3Color;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
//		warning3Color = [NSColor colorWithRed:255.0 / 255.0 green:38.0 / 255.0 blue:19.0 / 255.0 alpha:0.55];
		
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
		warning3Color = NSColor.systemRedColor;
#else
		warning3Color = NSColor.redColor;
#endif
	});
	return warning3Color;
}

@end
