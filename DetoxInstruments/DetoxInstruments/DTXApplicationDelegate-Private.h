//
//  DTXApplicationDelegate-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/23/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXApplicationDelegate.h"

extern NSString* const DTXCLIToolsInstallStatusChanged;

@interface DTXApplicationDelegate ()

- (NSURL*)_CLIUtilityURL;
- (NSURL*)_CLIInstallURL;
- (NSUInteger)_CLIInstallationStatus;
- (void)_uninstallAndPresentError:(BOOL)presentError;
- (void)_installCLIIntegration;
- (void)_uninstallCLIIntegration;

@end
