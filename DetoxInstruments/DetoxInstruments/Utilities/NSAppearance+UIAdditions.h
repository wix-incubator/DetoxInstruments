//
//  NSAppearance+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAppearance (UIAdditions)

@property (nonatomic, readonly, getter=isAppearanceDark) BOOL appearanceDark;

@end
