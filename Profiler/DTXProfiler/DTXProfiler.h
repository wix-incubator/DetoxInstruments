//
//  DTXProfiler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTXProfilingOptions : NSObject

@property (nonatomic) BOOL recordNetwork;
@property (nonatomic) NSTimeInterval samplingInterval;

+ (instancetype)defaultProfilingOptions;

@end

@interface DTXProfiler : NSObject

@property (assign, readonly, getter=isRecording) BOOL recording;

- (void)startProfilingWithOptions:(DTXProfilingOptions*)options;
- (void)stopProfiling;

- (void)pushSampleGroupWithName:(NSString*)name;
- (void)popSampleGroup;

- (void)addTag:(NSString*)tag;

@end
