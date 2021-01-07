//
//  DTXRecordingDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXDocument.h"
#import "DTXInstrumentsModel.h"
#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
#import "DTXRNJSCSourceMapsSupport.h"
#endif

#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
#import "DTXRemoteTarget.h"
#endif

extern NSString* const DTXRecordingDocumentDidLoadNotification;
extern NSString* const DTXRecordingDocumentDefactoEndTimestampDidChangeNotification;
extern NSString* const DTXRecordingDocumentStateDidChangeNotification;
extern NSString* const DTXRecordingLocalRecordingProfilingStateDidChangeNotification;

typedef NS_ENUM(NSUInteger, DTXRecordingDocumentState) {
	DTXRecordingDocumentStateNew,
	DTXRecordingDocumentStateLiveRecording,
	DTXRecordingDocumentStateLiveRecordingFinished,
	DTXRecordingDocumentStateSavedToDisk,
};

typedef NS_ENUM(NSUInteger, DTXRecordingLocalRecordingProfilingState) {
	DTXRecordingLocalRecordingProfilingStateUnknown,
	DTXRecordingLocalRecordingProfilingStateWaitingForAppLaunch,
	DTXRecordingLocalRecordingProfilingStateWaitingForAppData,
};

@interface DTXRecordingDocument : DTXDocument

@property (nonatomic, readonly) DTXRecordingDocumentState documentState;

@property (nonatomic, readonly) DTXRecordingLocalRecordingProfilingState localRecordingProfilingState;
@property (nonatomic, strong, readonly) NSString* localRecordingPendingAppName;

@property (nonatomic, strong, readonly) NSArray<DTXRecording*>* recordings;
@property (nonatomic, strong, readonly) DTXRecording* firstRecording;
@property (nonatomic, strong, readonly) DTXRecording* lastRecording;

@property (strong, readonly) NSManagedObjectContext *viewContext;
- (NSManagedObjectContext *)newBackgroundContext NS_RETURNS_RETAINED;
- (void)performBackgroundTask:(void (^)(NSManagedObjectContext *))block;

#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
@property (nonatomic, strong, readonly) DTXSourceMapsParser* sourceMapsParser;

- (void)readyForRecordingIfNeeded;
- (void)addTag;
- (void)stopLiveRecording;
#endif

@end

