//
//  DTXProfilingConfiguration+RemoteProfilingSupport.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration.h"

@interface DTXProfilingConfiguration ()

- (void)_setRecordingFileURL:(NSURL *)recordingFileURL;

@end

@interface DTXProfilingConfiguration (RemoteProfilingSupport)

- (void)setAsDefaultRemoteProfilingConfiguration;
+ (instancetype)profilingConfigurationForRemoteProfilingFromDefaults;

@end
