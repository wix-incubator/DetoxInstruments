//
//  DTXRecording+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecording+Additions.h"
#import "DTXProfilingConfiguration.h"

@interface DTXRecording (UIExtensions)

@property (nonatomic, copy, readonly) NSDate* realEndTimestamp;
@property (nonatomic, strong, readonly) DTXProfilingConfiguration* dtx_profilingConfiguration;
@property (nonatomic, readonly) BOOL hasNetworkSamples;

@end
