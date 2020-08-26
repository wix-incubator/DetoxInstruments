//
//  DTXLogSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/26/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXLogSample+CoreDataClass.h"
@import AppKit;

NS_ASSUME_NONNULL_BEGIN

@interface DTXLogSample (UIExtensions)

- (NSColor*)colorForLogLevel;
- (NSString*)logLevelDescription;

@end

NS_ASSUME_NONNULL_END
