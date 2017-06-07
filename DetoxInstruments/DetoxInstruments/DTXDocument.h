//
//  DTXDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInstrumentsModel.h"

extern NSString * const DTXDocumentDidLoadNotification;

@interface DTXDocument : NSDocument

@property (nonatomic, strong, readonly) DTXRecording* recording;

@end

