//
//  _DTXContainerContentsOutlineViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/1/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRemoteProfilingTarget.h"
#import "_DTXActionButtonProvider.h"

@interface _DTXContainerContentsOutlineViewController : NSViewController <_DTXActionButtonProvider>

@property (nonatomic, strong) DTXRemoteProfilingTarget* profilingTarget;

- (void)reloadContainerContentsOutline;
- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped;

@end
