//
//  DTXRemoteLaunchProfilingClient.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/1/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTXRemoteLaunchProfilingClient, DTXRemoteTarget;

@protocol DTXRemoteLaunchProfilingClientDelegate <NSObject>

- (void)remoteLaunchProfilingClientDidConnect:(DTXRemoteLaunchProfilingClient*)client;
- (void)remoteLaunchProfilingClient:(DTXRemoteLaunchProfilingClient*)client didFinishLaunchProfilingWithZippedData:(NSData*)zippedData;

@end

@interface DTXRemoteLaunchProfilingClient : NSObject

@property (nonatomic, strong, readonly) DTXRemoteTarget* target;
@property (nonatomic, weak) id<DTXRemoteLaunchProfilingClientDelegate> delegate;

- (instancetype)initWithLaunchProfilingSessionID:(NSString*)session;

- (void)startConnecting;
- (void)stop;

@end
