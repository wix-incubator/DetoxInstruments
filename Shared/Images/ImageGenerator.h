//
//  ImageGenerator.h
//  DetoxInstruments
//
//  Created by Artal Druk on 27/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageGenerator : NSObject

+ (NSImage*)createCancelImageWithSize:(int)cancelIconSize;
+ (NSImage*)createFilterImageWithSize:(int)filterIconSize highlighted:(BOOL)highlighted;

@end
