//
//  DTXRecordingTargetPickerViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DTXRecordingTargetPickerViewController;

@protocol DTXRecordingTargetPickerViewControllerDelegate <NSObject>

- (void)recordingTargetPickerDidCancel:(DTXRecordingTargetPickerViewController*)picker;
//- (void)recordingTargetPicker:(DTXRecordingTargetPickerViewController*)picker didSelectRecordingTarget:(id)target;

@end

@interface DTXRecordingTargetPickerViewController : NSViewController

@property (nonatomic, weak) id<DTXRecordingTargetPickerViewControllerDelegate> delegate;

@end
