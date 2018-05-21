//
//  DTXInspectorDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXInstrumentsModel.h"
#import "DTXRecordingDocument.h"
#import "DTXInspectorContentTableDataSource.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXProfilerWindowController.h"

@interface DTXInspectorDataProvider : NSObject <DTXWindowWideCopyHanler>

- (instancetype)initWithSample:(__kindof DTXSample*)sample document:(DTXRecordingDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) __kindof DTXSample* sample;
@property (nonatomic, strong, readonly) DTXRecordingDocument* document;

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource;

- (BOOL)canCopy;
- (BOOL)canSaveAs;

- (void)saveAs:(id)sender inWindow:(NSWindow*)window;

@end

@interface DTXTagInspectorDataProvider : DTXInspectorDataProvider @end
@interface DTXGroupInspectorDataProvider : DTXInspectorDataProvider @end
