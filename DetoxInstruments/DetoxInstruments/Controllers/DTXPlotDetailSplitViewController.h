//
//  DTXPlotDetailSplitViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/05/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXBaseSplitViewController.h"
#import "DTXRecordingDocument.h"

@interface DTXPlotDetailSplitViewController : DTXBaseSplitViewController

@property (nullable, assign) DTXRecordingDocument* document;

@property (nonatomic) BOOL splitViewHidden;
- (void)setProgressIndicatorTitle:(nullable NSString*)progressIndicatorTitle subtitle:(nullable NSString*)subtitle displaysProgress:(BOOL)displaysProgress;

@end
