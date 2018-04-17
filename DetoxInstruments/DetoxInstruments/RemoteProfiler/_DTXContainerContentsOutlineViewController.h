//
//  _DTXContainerContentsOutlineViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/1/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "_DTXDeviceServicesViewController.h"

@interface _DTXContainerContentsOutlineViewController : _DTXDeviceServicesViewController

- (void)showSaveDialogForSavingData:(NSData*)data dataWasZipped:(BOOL)wasZipped;

@end
