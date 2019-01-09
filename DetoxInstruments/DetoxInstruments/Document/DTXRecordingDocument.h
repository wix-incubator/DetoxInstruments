//
//  DTXRecordingDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXDocument.h"
#import "DTXInstrumentsModel.h"
#if ! CLI
#import "DTXRNJSCSourceMapsSupport.h"
#endif

#if ! CLI
#import "DTXRemoteTarget.h"
#endif

extern NSString* const DTXRecordingDocumentDidLoadNotification;
extern NSString* const DTXRecordingDocumentDefactoEndTimestampDidChangeNotification;
extern NSString* const DTXRecordingDocumentStateDidChangeNotification;

typedef NS_ENUM(NSUInteger, DTXRecordingDocumentState) {
	DTXRecordingDocumentStateNew,
	DTXRecordingDocumentStateLiveRecording,
	DTXRecordingDocumentStateLiveRecordingFinished,
	DTXRecordingDocumentStateSavedToDisk,
};

@interface DTXRecordingDocument : DTXDocument

@property (nonatomic) DTXRecordingDocumentState documentState;

//@property (nonatomic, strong, readonly) DTXRecording* recording;
@property (nonatomic, strong, readonly) NSArray<DTXRecording*>* recordings;
@property (nonatomic, strong, readonly) DTXRecording* firstRecording;
@property (nonatomic, strong, readonly) DTXRecording* lastRecording;

#if ! CLI
@property (nonatomic, strong, readonly) DTXSourceMapsParser* sourceMapsParser;

- (void)readyForRecordingIfNeeded;
- (void)addTag;
- (void)stopLiveRecording;
#endif

@end

