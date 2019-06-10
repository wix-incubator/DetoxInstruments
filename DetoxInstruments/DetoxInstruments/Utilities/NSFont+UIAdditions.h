//
//  NSFont+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/11/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFont (UIAdditions)

+ (NSFont *)dtx_monospacedSystemFontOfSize:(CGFloat)fontSize weight:(NSFontWeight)weight;

@end
