//
//  DTXDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInstrumentsModel.h"
#import "DTXRemoteProfilingTarget.h"

extern NSString* const DTXDocumentDidLoadNotification;
extern NSString* const DTXDocumentDefactoEndTimestampDidChangeNotification;
extern NSString* const DTXDocumentStateDidChangeNotification;

typedef NS_ENUM(NSUInteger, DTXDocumentState) {
	DTXDocumentStateNew,
	DTXDocumentStateLiveRecording,
	DTXDocumentStateLiveRecordingFinished,
	DTXDocumentStateSavedToDisk,
};

@interface DTXDocument : NSDocument

@property (nonatomic) DTXDocumentState documentState;
@property (nonatomic, strong, readonly) DTXRecording* recording;

- (void)readyForRecordingIfNeeded;
- (void)addTag;
- (void)pushGroup;
- (void)popGroup;
- (void)stopLiveRecording;

@end

