//
//  NSWindow+Snapshotting.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/9/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow (Snapshotting)

- (NSImage*)snapshotForCachingDisplay;

@end
