//
//  DTXDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInstrumentsModel.h"

extern NSString* const DTXDocumentDidLoadNotification;
extern NSString* const DTXDocumentDefactoEndTimestampDidChangeNotification;

typedef NS_ENUM(NSUInteger, DTXDocumentType) {
	DTXDocumentTypeNone,
	DTXDocumentTypeRecording,
	DTXDocumentTypeOpenedFromDisk,
};

@interface DTXDocument : NSDocument

@property (nonatomic) DTXDocumentType documentType;
@property (nonatomic, strong, readonly) DTXRecording* recording;

- (void)readyForRecordingIfNeeded;

@end

