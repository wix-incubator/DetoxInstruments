//
//  DTXProfilingConfiguration-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 12/1/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration.h"

@interface DTXProfilingConfiguration ()

+ (NSURL*)_urlForNewRecordingWithAppName:(NSString*)appName date:(NSDate*)date;
+ (NSURL*)_urlForLaunchRecordingWithSessionID:(NSString*)session;
+ (NSURL*)_urlForLaunchRecordingWithAppName:(NSString*)appName date:(NSDate*)date;

@end
