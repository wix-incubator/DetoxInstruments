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
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
		warning3Color = NSColor.systemRedColor;
#else
		warning3Color = NSColor.redColor;
#endif
	});
	return warning3Color;
}

- (NSColor *)darkerColor
{
	return [self blendedColorWithFraction:0.3 ofColor:NSColor.blackColor];
}

- (NSColor *)lighterColor
{
	return [self blendedColorWithFraction:0.15 ofColor:NSColor.whiteColor];
}

@end
