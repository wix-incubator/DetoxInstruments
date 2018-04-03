//
//  _DTXContainerContentsOutlineViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/1/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRemoteProfilingTarget.h"

@interface _DTXContainerContentsOutlineViewController : NSViewController

@property (nonatomic, strong) DTXRemoteProfilingTarget* profilingTarget;

@property (nonatomic, strong, readonly) NSButton* defaultButton;

- (void)reloadContainerContents;
- (void)showSaveDialogWithCompletionHandler:(void(^)(NSURL* saveLocation))completionHandler;

@end
