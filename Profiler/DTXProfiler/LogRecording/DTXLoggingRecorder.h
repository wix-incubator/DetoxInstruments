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
- (void)loggingRecorderDidAddLogLine:(NSString*)logLine objects:(NSArray*)objects;
@end

@interface DTXLoggingRecorder : NSObject

+ (void)addLoggingListener:(id<DTXLoggingListener>)listener;
+ (void)removeLoggingListener:(id<DTXLoggingListener>)listener;
+ (void)addLogLine:(NSString*)line objects:(NSArray*)objects;

@end
