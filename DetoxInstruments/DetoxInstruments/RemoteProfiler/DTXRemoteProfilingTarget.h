//
//  DTXRemoteProfilingTarget.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXFileSystemItem.h"
@import CoreData;

@class DTXRemoteProfilingTarget, DTXProfilingConfiguration;
@protocol DTXProfilerStoryDecoder;

typedef NS_ENUM(NSUInteger, DTXRemoteProfilingTargetState) {
	DTXRemoteProfilingTargetStateDiscovered,
	DTXRemoteProfilingTargetStateResolved,
	DTXRemoteProfilingTargetStateDeviceInfoLoaded,
	DTXRemoteProfilingTargetStateRecording,
	DTXRemoteProfilingTargetStateStopped,
};

@protocol DTXRemoteProfilingTargetDelegate <NSObject>

@optional

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteProfilingTarget*)target;
- (void)profilingTargetDidLoadDeviceInfo:(DTXRemoteProfilingTarget*)target;
- (void)profilingTargetdidLoadContainerContents:(DTXRemoteProfilingTarget*)target;
- (void)profilingTarget:(DTXRemoteProfilingTarget*)target didDownloadContainerContents:(NSData*)containerContentsZip;

@end

@interface DTXRemoteProfilingTarget : NSObject

@property (nonatomic, assign, readonly) NSUInteger deviceOSType;
@property (nonatomic, copy, readonly) NSString* appName;
@property (nonatomic, copy, readonly) NSString* deviceName;
@property (nonatomic, copy, readonly) NSString* deviceOS;
@property (nonatomic, copy, readonly) NSImage* deviceSnapshot;
@property (nonatomic, copy, readonly) NSDictionary* deviceInfo;

@property (nonatomic, strong, readonly) DTXFileSystemItem* containerContents;

@property (nonatomic, assign, readonly) DTXRemoteProfilingTargetState state;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, weak) id<DTXProfilerStoryDecoder> storyDecoder;
@property (nonatomic, weak) id<DTXRemoteProfilingTargetDelegate> delegate;

- (void)loadDeviceInfo;
- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;
- (void)addTagWithName:(NSString*)name;
- (void)pushSampleGroupWithName:(NSString*)name;
- (void)popSampleGroup;
- (void)stopProfiling;
- (void)loadContainerContents;
- (void)downloadContainer;

@end
