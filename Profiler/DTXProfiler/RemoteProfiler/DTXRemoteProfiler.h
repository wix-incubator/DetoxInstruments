//
//  DTXRemoteProfiler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXProfiler-Private.h"
#import "DTXSocketConnection.h"

@class DTXRemoteProfiler;

@protocol DTXRemoteProfilerDelegate <NSObject>

- (void)remoteProfiler:(DTXRemoteProfiler*)remoteProfiler didFinishWithError:(NSError*)error;

@end

@interface DTXRemoteProfiler : DTXProfiler

- (instancetype)initWithOpenedSocketConnection:(DTXSocketConnection*)connection remoteProfilerDelegate:(id<DTXRemoteProfilerDelegate>)remoteProfilerDelegate;

@property (nonatomic, weak, readonly) id<DTXRemoteProfilerDelegate> remoteProfilerDelegate;

@end
