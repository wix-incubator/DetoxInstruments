//
//  DTXInspectorDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXInstrumentsModel.h"
#import "DTXDocument.h"
#import "DTXInspectorContentTableDataSource.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXInstrumentsWindowController.h"

@interface DTXInspectorDataProvider : NSObject <DTXWindowWideCopyHanler>

- (instancetype)initWithSample:(__kindof DTXSample*)sample document:(DTXDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) __kindof DTXSample* sample;
@property (nonatomic, strong, readonly) DTXDocument* document;

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource;

- (BOOL)canCopy;
- (BOOL)canSaveAs;

- (void)saveAs:(id)sender inWindow:(NSWindow*)window;

@end
