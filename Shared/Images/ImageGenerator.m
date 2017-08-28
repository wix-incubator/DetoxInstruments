//
//  ImageGenerator.m
//  DetoxInstruments
//
//  Created by Artal Druk on 27/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "ImageGenerator.h"

typedef void (^DrawingBlock)(CGContextRef context, CGFloat scale);

@implementation ImageGenerator

+ (NSImage*) drawGraphicsWithPixelsWidth:(int)width pixelsHight:(int)height drawingBlock:(DrawingBlock)drawingBlock
{
	//CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
	CGSize imageSize = NSMakeSize(width, height);
	NSImage *nsImage = [[NSImage alloc] initWithSize:imageSize];
	for (int scale = 1; scale <= 3; scale++)
	{
		NSBitmapImageRep *bmpImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																				pixelsWide:width * scale pixelsHigh:height * scale
																			 bitsPerSample:8 samplesPerPixel:4
																				  hasAlpha:YES isPlanar:NO
																			colorSpaceName:NSCalibratedRGBColorSpace bitmapFormat:NSAlphaFirstBitmapFormat
																			   bytesPerRow:0 bitsPerPixel:0];
		[bmpImageRep setSize:imageSize];
		
		NSGraphicsContext *bitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bmpImageRep];
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bmpImageRep]];
		
		drawingBlock(bitmapContext.CGContext, scale);
		
		[NSGraphicsContext restoreGraphicsState];
		
		[nsImage addRepresentation:bmpImageRep];
	}
	
	return nsImage;
}

+ (void) drawHorizontalLineInContext:(CGContextRef)context iconsSize:(CGFloat)iconsSize offset:(CGPoint)offset
{
	CGContextMoveToPoint(context, offset.x, iconsSize - offset.y);
	CGContextAddLineToPoint(context, iconsSize - offset.x, iconsSize - offset.y);
}

+ (NSImage*)_createFilterImageWithSize:(int)filterIconSize highlighted:(BOOL)highlighted
{
	return [self drawGraphicsWithPixelsWidth:filterIconSize pixelsHight:filterIconSize drawingBlock:^(CGContextRef context, CGFloat scale){
		CGFloat lineWidth = (highlighted ? 1.5 : 1.0);
		CGContextSetLineWidth(context, lineWidth);
		highlighted ? CGContextSetRGBStrokeColor(context, 0.09, 0.49, 0.949, 1) : CGContextSetRGBStrokeColor(context, 0.482, 0.482, 0.482, 1);
		CGContextStrokeEllipseInRect(context, CGRectMake (lineWidth, lineWidth, filterIconSize - lineWidth * 2, filterIconSize - lineWidth * 2));
		
		CGContextBeginPath(context);
		{
			CGContextSetLineWidth(context, 1.0);
			CGFloat offset = scale == 1 ? 0.5 : 0;
			[self drawHorizontalLineInContext:context iconsSize:filterIconSize offset:CGPointMake(3.5, 5 + offset)];
			[self drawHorizontalLineInContext:context iconsSize:filterIconSize offset:CGPointMake(4.5, 7 + offset)];
			[self drawHorizontalLineInContext:context iconsSize:filterIconSize offset:CGPointMake(5.5, 9 + offset)];
		}
		CGContextStrokePath(context);
	}];
}

+ (NSImage*)createCancelImageWithSize:(int)cancelIconSize
{
	return [self drawGraphicsWithPixelsWidth:cancelIconSize pixelsHight:cancelIconSize drawingBlock:^(CGContextRef context, CGFloat scale) {
		CGFloat padding = 0.3 * cancelIconSize;
		NSSize imageSize = NSMakeSize(cancelIconSize, cancelIconSize);
		
		CGContextSetRGBFillColor(context, 0.482, 0.482, 0.482, 1);
		CGContextFillEllipseInRect(context, CGRectMake (0, 0, imageSize.width, imageSize.height));
		
		CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
		CGContextSetLineWidth(context, 1.25);
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, padding, padding);
		CGContextAddLineToPoint(context, cancelIconSize - padding, cancelIconSize - padding);
		CGContextMoveToPoint(context, padding, cancelIconSize - padding);
		CGContextAddLineToPoint(context, cancelIconSize - padding, padding);
		CGContextStrokePath(context);
	}];
}

+ (NSImage*)createFilterImageWithSize:(int)filterIconSize highlighted:(BOOL)highlighted
{
	static NSImage* filterColorImage = nil;
	static NSImage* highLightedFilterColorImage = nil;
	if(highlighted && highLightedFilterColorImage == nil)
	{
		highLightedFilterColorImage = [self _createFilterImageWithSize:filterIconSize highlighted:YES];
	}
	else if(!highlighted && filterColorImage == nil)
	{
		filterColorImage = [self _createFilterImageWithSize:filterIconSize highlighted:NO];
	}
	return highlighted ? highLightedFilterColorImage : filterColorImage;
}

@end
