//
//  NSWindowController+DocumentationGeneration.h
//  DetoxInstruments
//
//  Created by Leo Natan on 10/25/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

@import AppKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSWindowController (DocumentationGeneration)

- (void)_drainLayout;
- (void)_drainLayoutWithDuration:(NSTimeInterval)duration;
- (void)_setWindowSize:(NSSize)size;


@end

NS_ASSUME_NONNULL_END
