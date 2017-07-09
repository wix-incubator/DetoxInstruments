//
//  NSImage+ImageResize.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 09/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (ImageResize)

- (NSImage*)dtx_imageWithSize:(NSSize)size;

@end
