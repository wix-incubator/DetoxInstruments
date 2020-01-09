//
//  DTXFileInspectorContent.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/9/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXInspectorContentTableDataSource.h"

@interface DTXFileInspectorContent : DTXInspectorContent

+ (NSImageView*)previewImageView;
+ (void)saveData:(NSData*) data fileName:(NSString*)fileName inWindow:(NSWindow*)window;

@property (nonatomic, copy) NSString* fileName;
@property (nonatomic, strong) NSData* data;
@property (nonatomic, strong) NSButton* expandCloseButton;

@property (nonatomic, strong) NSView* contentView;

- (BOOL)expandPreview;

@end
