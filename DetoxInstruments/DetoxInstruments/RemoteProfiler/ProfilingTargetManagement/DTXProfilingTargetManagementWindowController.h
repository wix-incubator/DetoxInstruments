//
//  DTXProfilingTargetManagementWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/19/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "CCNPreferencesWindowController.h"
#import "DTXProfilingTargetManagement.h"

@interface DTXProfilingTargetManagementWindowController : CCNPreferencesWindowController

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget;
- (void)noteProfilingTargetDidLoadContainerContents;
- (void)noteProfilingTargetDidLoadUserDefaults;
- (void)noteProfilingTargetDidLoadCookies;

- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped;

@end
