//
//  NSImage+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/14/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
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

+ (NSImage*)imageWithColor:(NSColor*)color size:(NSSize)size
{
	NSImage *image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
	[color drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
//	[color set];
//	NSRectFill(NSMakeRect(0, 0, size.width, size.height));
	[image unlockFocus];
	return image;
}

- (NSImage *)imageTintedWithColor:(NSColor *)tint
{
	if(tint.alphaComponent == 0)
	{
		return [[NSImage alloc] initWithSize:self.size];
	}
	
	NSImage *image = [self copy];
	if (tint) {
		[image lockFocus];
		[tint set];
		NSRect imageRect = {NSZeroPoint, [image size]};
		NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
		[image unlockFocus];
	}
	return image;
}

@end
