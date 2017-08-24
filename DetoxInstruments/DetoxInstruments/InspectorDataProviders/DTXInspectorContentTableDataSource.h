//
//  DTXContentAwareTableDataSource.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import AppKit;
#import "DTXInstrumentsWindowController.h"
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

@property (nonatomic, copy) NSArray<DTXInspectorContentRow*>* content;

@property (nonatomic) BOOL setupForWindowWideCopy;

@property (nonatomic, strong) NSImage* image;
@property (nonatomic, strong) NSView* customView;
@property (nonatomic, copy) NSArray<DTXStackTraceFrame*>* stackFrames;
@property (nonatomic, copy) NSArray* objects;

@end

@interface DTXInspectorContentTableDataSource : NSObject

@property (nonatomic, weak) NSTableView* managedTableView;
@property (nonatomic, copy) NSArray<DTXInspectorContent*>* contentArray;

@end
