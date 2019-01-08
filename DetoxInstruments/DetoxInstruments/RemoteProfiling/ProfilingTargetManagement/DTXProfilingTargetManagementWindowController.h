//
//  DTXProfilingTargetManagementWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/19/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "CCNPreferencesWindowController.h"
#import "DTXProfilingTargetManagement.h"

@interface DTXProfilingTargetManagementWindowController : CCNPreferencesWindowController

@property (nonatomic, strong) DTXRemoteTarget* profilingTarget;

- (void)noteProfilingTargetDidLoadContainerContents;
- (void)noteProfilingTargetDidLoadUserDefaults;
- (void)noteProfilingTargetDidLoadCookies;
- (void)noteProfilingTargetDidLoadPasteboardContents;

- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped;

@end
