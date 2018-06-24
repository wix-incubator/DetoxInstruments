//
//  NSColor+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import AppKit;
#import "DTXRemoteProfilingBasics.h"

@interface NSColor (NamedColors)

@property (class, nonatomic, strong, readonly) NSColor* warningColor;
@property (class, nonatomic, strong, readonly) NSColor* warning2Color;
@property (class, nonatomic, strong, readonly) NSColor* warning3Color;

@property (class, nonatomic, strong, readonly) NSColor* cpuUsagePlotControllerColor;
@property (class, nonatomic, strong, readonly) NSColor* memoryUsagePlotControllerColor;
@property (class, nonatomic, strong, readonly) NSColor* fpsPlotControllerColor;
@property (class, nonatomic, strong, readonly) NSColor* diskReadPlotControllerColor;
@property (class, nonatomic, strong, readonly) NSColor* diskWritePlotControllerColor;
@property (class, nonatomic, strong, readonly) NSColor* networkRequestsPlotControllerColor;

@property (class, nonatomic, strong, readonly) NSColor* signpostPlotControllerColor;
+ (NSColor*)signpostPlotControllerColorForCategory:(DTXEventStatus)eventStatus;

@end

@interface NSColor (UIAdditions)

- (NSColor*)deeperColorWithAppearance:(NSAppearance*)appearance modifier:(CGFloat)modifier;
- (NSColor*)shallowerColorWithAppearance:(NSAppearance*)appearance modifier:(CGFloat)modifier;

+ (NSColor*)randomColorWithSeed:(NSString*)seed;

@end
