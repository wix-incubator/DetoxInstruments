//
//  DTXRemoteProfiler.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXProfiler-Private.h"
#import "DTXSocketConnection.h"

@class DTXRemoteProfiler;

@protocol DTXRemoteProfilerDelegate <NSObject>

- (void)remoteProfilerDidFinish:(DTXRemoteProfiler*)remoteProfiler;

@end

@interface DTXRemoteProfiler : DTXProfiler

- (instancetype)initWithSocketConnection:(DTXSocketConnection*)connection remoteProfilerDelegate:(id<DTXRemoteProfilerDelegate>)remoteProfilerDelegate;

@property (nonatomic, weak, readonly) id<DTXRemoteProfilerDelegate> remoteProfilerDelegate;

@end
