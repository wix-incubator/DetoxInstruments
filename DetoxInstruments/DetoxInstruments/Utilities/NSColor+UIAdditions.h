//
//  NSColor+UIAdditions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import AppKit;
#import "DTXEventStatusPrivate.h"

@interface NSColor (NamedColors)

@property (class, nonatomic, strong, readonly) NSColor* successColor;
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
@property (class, nonatomic, strong, readonly) NSColor* activityPlotControllerColor;

@property (class, nonatomic, strong, readonly) NSColor* pasteboardTypeColorColor;
@property (class, nonatomic, strong, readonly) NSColor* pasteboardTypeImageColor;
@property (class, nonatomic, strong, readonly) NSColor* pasteboardTypeLinkColor;
@property (class, nonatomic, strong, readonly) NSColor* pasteboardTypeRichTextColor;
@property (class, nonatomic, strong, readonly) NSColor* pasteboardTypeTextColor;

@property (class, nonatomic, strong, readonly) NSColor* graphitePlotColor;

@end

typedef NS_ENUM(NSUInteger, DTXColorEffect) {
	DTXColorEffectNormal,
	DTXColorEffectPending,
	DTXColorEffectCancelled,
	DTXColorEffectError
};

@interface NSColor (UIAdditions)

@property (nonatomic, strong, readonly) NSColor* invertedColor;
@property (nonatomic, readonly) BOOL isDarkColor;

- (NSColor*)deeperColorWithAppearance:(NSAppearance*)appearance modifier:(CGFloat)modifier;
- (NSColor*)shallowerColorWithAppearance:(NSAppearance*)appearance modifier:(CGFloat)modifier;

- (NSColor*)darkerColorWithModifier:(CGFloat)modifier;
- (NSColor*)lighterColorWithModifier:(CGFloat)modifier;

+ (NSColor*)randomColorWithSeed:(NSString*)seed;

+ (NSColor*)uiColorWithSeed:(NSString*)seed effect:(DTXColorEffect)effect;

@end
