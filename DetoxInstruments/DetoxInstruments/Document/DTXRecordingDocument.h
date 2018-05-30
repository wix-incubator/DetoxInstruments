//
//  DTXRecordingDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInstrumentsModel.h"

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

@interface DTXRecordingDocument : NSDocument

@property (nonatomic) DTXRecordingDocumentState documentState;
@property (nonatomic, strong, readonly) DTXRecording* recording;

#ifndef CLI
- (void)readyForRecordingIfNeeded;
- (void)addTag;
- (void)pushGroup;
- (void)popGroup;
- (void)stopLiveRecording;
#endif

@end

