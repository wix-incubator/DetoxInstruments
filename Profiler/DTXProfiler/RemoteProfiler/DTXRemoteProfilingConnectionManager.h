//
//  DTXRemoteProfilingConnectionManager.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/25/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTXRemoteProfilingConnectionManager;

@protocol DTXRemoteProfilingConnectionManagerDelegate <NSObject>

- (void)remoteProfilingConnectionManagerDidStartProfiling:(DTXRemoteProfilingConnectionManager*)manager;
- (void)remoteProfilingConnectionManager:(DTXRemoteProfilingConnectionManager*)manager didFinishWithError:(NSError*)error;

@end

@interface DTXRemoteProfilingConnectionManager : NSObject

@property (nonatomic, readonly, getter=isProfiling) BOOL profiling;
@property (nonatomic, weak) id<DTXRemoteProfilingConnectionManagerDelegate> delegate;

- (instancetype)initWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream;

- (void)abortConnectionAndProfiling;

@end
