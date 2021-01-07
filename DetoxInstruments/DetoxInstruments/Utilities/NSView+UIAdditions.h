//
//  NSView+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (UIAdditions)

- (NSImage*)snapshotForCachingDisplay;
- (void)scrollToBottom;

@end
