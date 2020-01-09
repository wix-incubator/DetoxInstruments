//
//  DTXInspectorContentController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/05/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInspectorDataProvider.h"

@interface DTXInspectorContentController : NSViewController

@property (nonatomic, strong) DTXRecordingDocument* document;
@property (nonatomic, strong) DTXInspectorDataProvider* inspectorDataProvider;

- (void)selectExtendedDetail;
- (void)selectProfilingInfo;

- (BOOL)expandPreview;

@end
