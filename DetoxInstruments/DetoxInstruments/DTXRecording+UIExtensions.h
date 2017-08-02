//
//  DTXRecording+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecording+Additions.h"
#import "DTXProfilingConfiguration.h"

extern NSString* const DTXRecordingDidInvalidateDefactoEndTimestamp;

@interface DTXRecording (UIExtensions)

@property (nonatomic, copy, readonly) NSDate* defactoStartTimestamp;

@property (nonatomic) NSTimeInterval minimumDefactoTimeInterval;
@property (nonatomic, copy, readonly) NSDate* defactoEndTimestamp;
- (void)invalidateDefactoEndTimestamp;

@property (nonatomic, strong, readonly) DTXProfilingConfiguration* dtx_profilingConfiguration;
@property (nonatomic, readonly) BOOL hasNetworkSamples;

@end
