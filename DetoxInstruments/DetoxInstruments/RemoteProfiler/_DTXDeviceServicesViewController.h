//
//  _DTXDeviceServicesViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/18/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRemoteProfilingTarget.h"
#import "_DTXActionButtonProvider.h"

@interface _DTXDeviceServicesViewController : NSViewController <_DTXActionButtonProvider>

@property (nonatomic, strong) DTXRemoteProfilingTarget* profilingTarget;

- (void)noteProfilingTargetDidLoadServiceData;

@end
