//
//  NSColor+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSColor+UIAdditions.h"
#import <LNInterpolation/LNInterpolation.h>

@implementation NSColor (UIAdditions)

+ (NSColor *)warningColor
{
	static NSColor* warningColor;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		warningColor = NSColor.systemYellowColor;
	});
	return warningColor;
}

+ (NSColor *)warning2Color
{
	static NSColor* warning2Color;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		warning2Color = NSColor.systemOrangeColor;
	});
	return warning2Color;
}

+ (NSColor *)warning3Color
{
	static NSColor* warning3Color;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		warning3Color = NSColor.systemRedColor;
	});
	return warning3Color;
}

- (NSColor *)darkerColor
{
	return [self interpolateToValue:NSColor.blackColor progress:0.3];
}

- (NSColor *)lighterColor
{
	return [self interpolateToValue:NSColor.whiteColor progress:0.15];
}

+ (NSColor*)randomColorWithSeed:(NSString*)seed;
{
	srand48(seed.hash * 200);
	double r = drand48();
	
	srand48(seed.hash);
	double g = drand48();
	
	srand48(seed.hash / 200);
	double b = drand48();
	
	return [NSColor colorWithRed:r green:g blue:b alpha:1.0];
	
//	srand48(total * 200)
//	let r = CGFloat(drand48())
//
//	srand48(total)
//	let g = CGFloat(drand48())
//
//	srand48(total / 200)
//	let b = CGFloat(drand48())
//
//	return UIColor(red: r, green: g, blue: b, alpha: 1)
	
//	return [NSColor systemBlueColor];
}

@end
