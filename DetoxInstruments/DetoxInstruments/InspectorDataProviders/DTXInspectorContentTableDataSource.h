//
//  DTXContentAwareTableDataSource.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

@import AppKit;
#import "DTXWindowController.h"
#import "DTXStackTraceFrame.h"

@interface DTXInspectorContentRow : NSObject

@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* description;
@property (nonatomic, copy) NSAttributedString* attributedDescription;
@property (nonatomic, strong) NSColor* color;

+ (instancetype)contentRowWithTitle:(NSString*)title attributedDescription:(NSAttributedString*)attributedDescription;
+ (instancetype)contentRowWithTitle:(NSString*)title description:(NSString*)description color:(NSColor*)color;
+ (instancetype)contentRowWithTitle:(NSString*)title description:(NSString*)description;
+ (instancetype)contentRowWithNewLine;

- (BOOL)isNewLine;

@end

@interface DTXInspectorContent : NSObject

@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSAttributedString* attributedTitle;
@property (nonatomic, copy) NSImage* titleImage;
@property (nonatomic, copy) NSColor* titleColor;

@property (nonatomic) BOOL isGroup;

@property (nonatomic, copy) NSArray<DTXInspectorContentRow*>* content;

@property (nonatomic, strong) NSImage* image;
@property (nonatomic, strong) NSView* customView;
@property (nonatomic, copy) NSArray<DTXStackTraceFrame*>* stackFrames;
@property (nonatomic, copy) NSArray<NSButton*>* buttons;
@property (nonatomic, copy) NSArray<id>* objects;

@property (nonatomic) BOOL selectionDisabled;

@property (nonatomic, copy) void(^copyHandler)(__kindof NSView* targetView, id sender);

@end

@interface DTXInspectorContentTableDataSource : NSObject

@property (nonatomic, weak) NSTableView* managedTableView;
@property (nonatomic, copy) NSArray<DTXInspectorContent*>* contentArray;
- (void)setContentArray:(NSArray<DTXInspectorContent *> *)contentArray animateTransition:(BOOL)animate;

@end
