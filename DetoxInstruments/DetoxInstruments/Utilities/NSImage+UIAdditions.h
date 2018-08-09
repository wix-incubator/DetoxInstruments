//
//  NSImage+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/14/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (UIAdditions)

+ (NSImage*)imageWithColor:(NSColor*)color size:(NSSize)size;
- (NSImage *)imageTintedWithColor:(NSColor *)tint;

@end
