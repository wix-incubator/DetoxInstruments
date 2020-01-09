//
//  DTXInspectorDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXInstrumentsModel.h"
#import "DTXRecordingDocument.h"
#import "DTXInspectorContentTableDataSource.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXWindowController.h"

@interface DTXInspectorDataProvider : NSObject

- (instancetype)initWithSample:(__kindof DTXSample*)sample document:(DTXRecordingDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) __kindof DTXSample* sample;
@property (nonatomic, strong, readonly) DTXRecordingDocument* document;

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource;

- (BOOL)canCopyInView:(__kindof NSView*)view;
- (void)copyInView:(__kindof NSView*)view sender:(id)sender;

- (BOOL)canSaveAs;
- (void)saveAs:(id)sender inWindow:(NSWindow*)window;

@end

@interface DTXTagInspectorDataProvider : DTXInspectorDataProvider @end
@interface DTXGroupInspectorDataProvider : DTXInspectorDataProvider @end

@interface DTXRangeInspectorDataProvider : DTXInspectorDataProvider

- (instancetype)initWithSamples:(NSArray<__kindof DTXSample*>*)samples sortDescriptors:(NSArray<NSSortDescriptor*>*)sortDescriptors document:(DTXRecordingDocument*)document;

- (instancetype)initWithSample:(__kindof DTXSample*)sample document:(DTXRecordingDocument*)document NS_UNAVAILABLE;
@property (nonatomic, strong, readonly) __kindof DTXSample* sample NS_UNAVAILABLE;

@end
