//
//  DTXProfiler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DTXProfilingOptions : NSObject

@property (nonatomic) BOOL recordNetwork;
@property (nonatomic) NSTimeInterval samplingInterval;
@property (nonatomic, copy, null_resettable) NSURL* recordingFileURL;

+ (instancetype)defaultProfilingOptions;

@end

@interface DTXProfiler : NSObject

@property (assign, readonly, getter=isRecording) BOOL recording;

- (void)startProfilingWithOptions:(DTXProfilingOptions*)options;
- (void)stopProfiling;

- (void)pushSampleGroupWithName:(NSString*)name;
- (void)popSampleGroup;

- (void)addTag:(NSString*)tag;
- (void)addLogLine:(NSString*)line;

@end

NS_ASSUME_NONNULL_END
