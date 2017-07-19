//
//  DTXLoggingRecorder.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 28/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int DTXStdErr;

@protocol DTXLoggingListener <NSObject>
- (void)loggingRecorderDidAddLogLine:(NSString*)logLine;
@end

@interface DTXLoggingRecorder : NSObject

+ (void)addLoggingListener:(id<DTXLoggingListener>)listener;
+ (void)removeLoggingListener:(id<DTXLoggingListener>)listener;

@end
