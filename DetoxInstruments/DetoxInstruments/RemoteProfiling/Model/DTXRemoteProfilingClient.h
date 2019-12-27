//
//  DTXRemoteProfilingClient.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 26/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRemoteTarget.h"
#import "DTXRecordingDocument.h"
#import "DTXRNJSCSourceMapsSupport.h"

@class DTXRemoteProfilingClient;

@protocol DTXRemoteProfilingClientDelegate <NSObject>

@property (nonatomic, strong, readonly) DTXSourceMapsParser* sourceMapsParser;

- (void)remoteProfilingClient:(DTXRemoteProfilingClient*)client didCreateRecording:(DTXRecording*)recording;
- (void)remoteProfilingClient:(DTXRemoteProfilingClient*)client didReceiveSourceMapsData:(NSData*)sourceMapsData;
- (void)remoteProfilingClientDidChangeDatabase:(DTXRemoteProfilingClient*)client;
- (void)remoteProfilingClient:(DTXRemoteProfilingClient*)client didStopRecordingWithZippedRecordingData:(NSData*)zipData;

@end

@interface DTXRemoteProfilingClient : NSObject <DTXProfilerStoryDecoder>

@property (nonatomic, strong, readonly) DTXRemoteTarget* target;
@property (nonatomic, strong, readonly) NSManagedObjectContext* managedObjectContext;

@property (nonatomic, weak) id<DTXRemoteProfilingClientDelegate> delegate;

- (instancetype)initWithProfilingTarget:(DTXRemoteTarget*)target managedObjectContext:(NSManagedObjectContext*)ctx;
- (instancetype)initWithProfilingTargetForLocalRecording:(DTXRemoteTarget*)target;

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;
- (void)stopProfiling;

@end
