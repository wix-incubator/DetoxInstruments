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
		warningColor = NSColor.systemYellowColor;
	});
	return warningColor;
}

+ (NSColor *)warning2Color
{
	static NSColor* warning2Color;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
//		warning2Color = [NSColor colorWithRed:244.0 / 255.0 green:108.0 / 255.0 blue:63.0 / 255.0 alpha:0.25];
		warning2Color = NSColor.systemOrangeColor;
	});
	return warning2Color;
}

+ (NSColor *)warning3Color
{
	static NSColor* warning3Color;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
//		warning3Color = [NSColor colorWithRed:255.0 / 255.0 green:38.0 / 255.0 blue:19.0 / 255.0 alpha:0.55];
		warning3Color = NSColor.systemRedColor;
	});
	return warning3Color;
}

@end
