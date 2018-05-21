//
//  DTXInspectorContentController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInspectorDataProvider.h"

@interface DTXInspectorContentController : NSViewController

@property (nonatomic, strong) DTXRecordingDocument* document;
@property (nonatomic, strong) DTXInspectorDataProvider* moreInfoDataProvider;

- (void)selectExtendedDetail;
- (void)selectProfilingInfo;

@end
