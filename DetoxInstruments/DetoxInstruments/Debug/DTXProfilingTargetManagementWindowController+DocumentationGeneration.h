//
//  DTXProfilingTargetManagementWindowController+DocumentationGeneration.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/15/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXProfilingTargetManagementWindowController.h"

@interface DTXProfilingTargetManagementWindowController (DocumentationGeneration)

- (void)_drainLayout;
- (void)_activateControllerAtIndex:(NSUInteger)index;

- (void)_expandFolders;
- (void)_expandDefaults;
- (void)_expandCookies;
- (void)_selectDateInCookies;
- (void)_selectSomethingInDefaults;

@end
