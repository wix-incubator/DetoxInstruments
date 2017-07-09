//
//  DTXContentAwareTableDataSource.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import AppKit;

@interface DTXInspectorContentRow : NSObject

@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* description;
@property (nonatomic, strong) NSColor* color;

+ (instancetype)contentRowWithTitle:(NSString*)title description:(NSString*)description color:(NSColor*)color;
+ (instancetype)contentRowWithTitle:(NSString*)title description:(NSString*)description;
+ (instancetype)contentRowWithNewLine;

- (BOOL)isNewLine;

@end

@interface DTXInspectorContent : NSObject

@property (nonatomic, copy) NSString* title;

@property (nonatomic, copy) NSArray<DTXInspectorContentRow*>* content;
@property (nonatomic, strong) NSImage* image;
@property (nonatomic, strong) NSView* customView;
@property (nonatomic, copy) NSArray<NSAttributedString*>* stackFrames;

@end

@interface DTXInspectorContentTableDataSource : NSObject

@property (nonatomic, weak) NSTableView* managedTableView;
@property (nonatomic, copy) NSArray<DTXInspectorContent*>* contentArray;

@end
