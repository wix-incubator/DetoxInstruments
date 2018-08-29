//
//  DTXRecording+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecording+Additions.h"

extern NSString* const DTXRecordingDidInvalidateDefactoEndTimestamp;

@interface DTXRecording (UIExtensions)

@property (nonatomic, copy, readonly) NSDate* defactoStartTimestamp;

@property (nonatomic, copy, readonly) NSDate* defactoEndTimestamp;
- (void)invalidateDefactoEndTimestamp;

@property (nonatomic, readonly) BOOL hasNetworkSamples;

@end
