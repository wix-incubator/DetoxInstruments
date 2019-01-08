//
//  NSAppearance+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAppearance (UIAdditions)

@property (nonatomic, readonly, getter=isDarkAppearance) BOOL darkAppearance;
@property (nonatomic, readonly, getter=isTouchBarAppearance) BOOL touchBarAppearance;

- (void)performBlockAsCurrentAppearance:(void(^)(void))block;

@end
