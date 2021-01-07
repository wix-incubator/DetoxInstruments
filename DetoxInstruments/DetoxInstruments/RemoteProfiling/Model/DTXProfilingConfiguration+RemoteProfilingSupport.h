//
//  DTXProfilingConfiguration+RemoteProfilingSupport.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/08/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration.h"

@interface DTXProfilingConfiguration (RemoteProfilingSupport)

+ (void)registerRemoteProfilingDefaults;
+ (void)resetRemoteProfilingDefaults;
+ (instancetype)profilingConfigurationForRemoteProfilingFromDefaults;

@end
