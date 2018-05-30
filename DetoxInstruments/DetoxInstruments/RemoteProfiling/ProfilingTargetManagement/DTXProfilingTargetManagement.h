//
//  _DTXDeviceServicesViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/18/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRemoteTarget.h"
#import "CCNPreferencesWindowControllerProtocol.h"

@protocol DTXProfilingTargetManagement <NSObject, CCNPreferencesWindowControllerProtocol>

@property (nonatomic, strong) DTXRemoteTarget* profilingTarget;

- (void)noteProfilingTargetDidLoadServiceData;

@end
