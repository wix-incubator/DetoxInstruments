//
//  NSColor+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (UIAdditions)

@property (class, strong, readonly) NSColor* themeTextColor;
@property (class, strong, readonly) NSColor* themeSelectedTextColor;
@property (class, strong, readonly) NSColor* themeGridColor;
@property (class, strong, readonly) NSColor* themeControlBackgroundColor;
@property (class, strong, readonly) NSColor* themeDisabledControlTextColor;

@property (class, nonatomic, strong, readonly) NSColor* warningColor;
@property (class, nonatomic, strong, readonly) NSColor* warning2Color;
@property (class, nonatomic, strong, readonly) NSColor* warning3Color;

@property (nonatomic, strong, readonly) NSColor* darkerColor;
@property (nonatomic, strong, readonly) NSColor* lighterColor;

@end
