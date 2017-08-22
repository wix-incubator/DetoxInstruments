//
//  NSColor+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if __MAC_OS_X_VERSION_MAX_ALLOWED <= __MAC_10_12_4

@interface NSColor ()

@property (class, strong, readonly) NSColor *systemRedColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemGreenColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemBlueColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemOrangeColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemYellowColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemBrownColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemPinkColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemPurpleColor NS_AVAILABLE_MAC(10_10);
@property (class, strong, readonly) NSColor *systemGrayColor NS_AVAILABLE_MAC(10_10);

@end

#endif

@interface NSColor (UIAdditions)

@property (class, nonatomic, strong, readonly) NSColor* warningColor;
@property (class, nonatomic, strong, readonly) NSColor* warning2Color;
@property (class, nonatomic, strong, readonly) NSColor* warning3Color;

@property (nonatomic, strong, readonly) NSColor* darkerColor;
@property (nonatomic, strong, readonly) NSColor* lighterColor;

@end
