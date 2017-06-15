//
//  DTXContentAwareTableDataSource.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import AppKit;

@interface DTXInspectorContent : NSObject

@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* content;
@property (nonatomic, copy) NSImage* image;

@end

@interface DTXInspectorContentTableDataSource : NSObject

@property (nonatomic, weak) NSTableView* managedTableView;
@property (nonatomic, copy) NSArray<DTXInspectorContent*>* contentArray;

@end
