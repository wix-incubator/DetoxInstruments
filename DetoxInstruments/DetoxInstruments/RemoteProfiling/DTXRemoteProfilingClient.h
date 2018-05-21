//
//  DTXRemoteProfilingClient.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 26/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRemoteProfilingTarget.h"
#import "DTXRecordingDocument.h"

@class DTXRemoteProfilingClient;

@protocol DTXRemoteProfilingClientDelegate <NSObject>

- (void)remoteProfilingClient:(DTXRemoteProfilingClient*)client didCreateRecording:(DTXRecording*)recording;
- (void)remoteProfilingClientDidChangeDatabase:(DTXRemoteProfilingClient*)client;
- (void)remoteProfilingClientDidStopRecording:(DTXRemoteProfilingClient*)client;

@end

@interface DTXRemoteProfilingClient : NSObject

@property (nonatomic, strong, readonly) DTXRemoteProfilingTarget* target;
@property (nonatomic, strong, readonly) NSManagedObjectContext* managedObjectContext;

@property (nonatomic, weak) id<DTXRemoteProfilingClientDelegate> delegate;

- (instancetype)initWithProfilingTarget:(DTXRemoteProfilingTarget*)target managedObjectContext:(NSManagedObjectContext*)ctx;

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;
- (void)stopWithCompletionHandler:(void (^)(void))completionHandler;

@end
