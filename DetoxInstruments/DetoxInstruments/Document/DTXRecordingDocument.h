//
//  DTXRecordingDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXDocument.h"
#import "DTXInstrumentsModel.h"
#ifndef CLI
#import "DTXRNJSCSourceMapsSupport.h"
#endif

#ifndef CLI
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

#ifndef CLI
@property (nonatomic, strong, readonly) DTXSourceMapsParser* sourceMapsParser;

+ (void)clearLastOpenedVersionAndReopenDocumentAtURL:(NSURL*)URL;

- (void)readyForRecordingIfNeeded;
- (void)addTag;
- (void)pushGroup;
- (void)popGroup;
- (void)stopLiveRecording;
#endif

@end

