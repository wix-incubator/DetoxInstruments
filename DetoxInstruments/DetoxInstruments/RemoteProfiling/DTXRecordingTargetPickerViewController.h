//
//  DTXRecordingTargetPickerViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRemoteProfilingTarget.h"

@class DTXRecordingTargetPickerViewController;
@class DTXProfilingConfiguration;

@protocol DTXRecordingTargetPickerViewControllerDelegate <NSObject>

- (void)recordingTargetPickerDidCancel:(DTXRecordingTargetPickerViewController*)picker;
- (void)recordingTargetPicker:(DTXRecordingTargetPickerViewController*)picker didSelectRemoteProfilingTarget:(DTXRemoteProfilingTarget*)target profilingConfiguration:(DTXProfilingConfiguration*)configuration;


@end

@interface DTXRecordingTargetPickerViewController : NSViewController

@property (nonatomic, weak) id<DTXRecordingTargetPickerViewControllerDelegate> delegate;

@end
