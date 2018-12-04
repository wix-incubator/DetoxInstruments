//
//  DTXRemoteTarget.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXProfilingBasics.h"
#import "DTXFileSystemItem.h"
#import "DTXPasteboardItem.h"
@import CoreData;

@class DTXRemoteTarget, DTXProfilingConfiguration;
@protocol DTXProfilerStoryDecoder;

typedef NS_ENUM(NSUInteger, DTXRemoteTargetState) {
	DTXRemoteTargetStateDiscovered,
	DTXRemoteTargetStateResolved,
	DTXRemoteTargetStateDeviceInfoLoaded,
	DTXRemoteTargetStateRecording,
	DTXRemoteTargetStateStopped,
};

@protocol DTXRemoteTargetDelegate <NSObject>

@optional

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteTarget*)target;

- (void)profilingTargetDidLoadDeviceInfo:(DTXRemoteTarget*)target;
- (void)profilingTargetDidLoadScreenSnapshot:(DTXRemoteTarget*)target;

- (void)profilingTargetdidLoadContainerContents:(DTXRemoteTarget*)target;
- (void)profilingTarget:(DTXRemoteTarget*)target didDownloadContainerContents:(NSData*)containerContents wasZipped:(BOOL)wasZipped;

- (void)profilingTarget:(DTXRemoteTarget*)target didLoadUserDefaults:(NSDictionary*)userDefaults;

- (void)profilingTarget:(DTXRemoteTarget*)target didLoadCookies:(NSArray<NSDictionary<NSString*, id>*>*)cookies;

- (void)profilingTarget:(DTXRemoteTarget*)target didLoadPasteboardContents:(NSArray<DTXPasteboardItem*>*)pasteboardContents;

@end

@interface DTXRemoteTarget : NSObject

@property (nonatomic, assign, readonly) NSUInteger deviceOSType;
@property (nonatomic, copy, readonly) NSString* appName;
@property (nonatomic, copy, readonly) NSString* deviceName;
@property (nonatomic, copy, readonly) NSString* devicePresentable;
@property (nonatomic, copy, readonly) NSImage* deviceSnapshot;
@property (nonatomic, copy, readonly) NSDictionary* deviceInfo;
@property (nonatomic, strong, readonly) NSImage* screenSnapshot;

@property (nonatomic, readonly, getter=isCompatibleWithInstruments) BOOL compatibleWithInstruments;

@property (nonatomic, assign, readonly) DTXRemoteTargetState state;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, weak) id<DTXProfilerStoryDecoder> storyDecoder;
@property (nonatomic, weak) id<DTXRemoteTargetDelegate> delegate;

- (void)loadDeviceInfo;
- (void)loadScreenSnapshot;
- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration;
- (void)addTagWithName:(NSString*)name;
- (void)pushSampleGroupWithName:(NSString*)name;
- (void)popSampleGroup;
- (void)stopProfiling;

@property (nonatomic, strong, readonly) DTXFileSystemItem* containerContents;
- (void)loadContainerContents;
- (void)downloadContainerItemsAtURL:(NSURL*)URL;
- (void)deleteContainerItemAtURL:(NSURL*)URL;
- (void)putContainerItemAtURL:(NSURL *)URL data:(NSData *)data wasZipped:(BOOL)wasZipped;

@property (nonatomic, copy, readonly) NSDictionary<NSString*, id>* userDefaults;
- (void)loadUserDefaults;
- (void)changeUserDefaultsItemWithKey:(NSString*)key changeType:(DTXUserDefaultsChangeType)changeType value:(id)value previousKey:(NSString*)previousKey;

@property (nonatomic, copy) NSArray<NSDictionary<NSString*, id>*>* cookies;
- (void)loadCookies;

@property (nonatomic, copy) NSArray<DTXPasteboardItem*>* pasteboardContents;
- (void)loadPasteboardContents;

- (void)captureViewHierarchy;


@end
