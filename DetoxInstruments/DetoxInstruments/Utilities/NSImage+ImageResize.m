//
//  NSImage+ImageResize.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 09/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSImage+ImageResize.h"

@implementation NSImage (ImageResize)

- (NSImage*)dtx_imageWithSize:(NSSize)size;
{
	/*var destSize = NSMakeSize(CGFloat(w), CGFloat(h))
	 var newImage = NSImage(size: destSize)
	 newImage.lockFocus()
	 image.drawInRect(NSMakeRect(0, 0, destSize.width, destSize.height), fromRect: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.CompositeSourceOver, fraction: CGFloat(1))
	 newImage.unlockFocus()
	 newImage.size = destSize
	 return NSImage(data: newImage.TIFFRepresentation!)!*/
	
	NSImage* rv = [[NSImage alloc] initWithSize:size];
	[rv lockFocus];
	NSGraphicsContext.currentContext.imageInterpolation = NSImageInterpolationHigh;
	[self drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSMakeRect(0, 0, self.size.width, self.size.height) operation:NSCompositingOperationSourceOver fraction:1.0];
	[rv unlockFocus];
	
	return rv;
}

@end
