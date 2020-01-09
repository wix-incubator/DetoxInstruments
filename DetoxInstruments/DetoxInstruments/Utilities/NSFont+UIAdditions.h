//
//  NSFont+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/11/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFont (UIAdditions)

+ (NSFont *)dtx_monospacedSystemFontOfSize:(CGFloat)fontSize weight:(NSFontWeight)weight;

@property (nonatomic, readonly, copy) NSURL* fontURL;

@end
