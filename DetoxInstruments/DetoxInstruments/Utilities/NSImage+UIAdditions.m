//
//  NSImage+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/14/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSImage+UIAdditions.h"
@import ObjectiveC;

@implementation NSImage (UIAdditions)

+ (instancetype)__dtx_imageNamed:(NSString*)name
{
	if([name isEqualToString:@"NSPathLocationArrow"])
	{
		name = @"right-chevron";
	}
	
	return [self __dtx_imageNamed:name];
}

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Method m1 = class_getClassMethod([NSImage class], @selector(imageNamed:));
		Method m2 = class_getClassMethod([NSImage class], @selector(__dtx_imageNamed:));
		method_exchangeImplementations(m1, m2);
	});
}

@end
