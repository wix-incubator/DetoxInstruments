//
//  DTXRecording+Additions.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRecording+CoreDataClass.h"
#import "DTXProfilingConfiguration.h"

@interface DTXRecording (Additions)

@property (nonatomic, strong, readonly) DTXProfilingConfiguration* dtx_profilingConfiguration;

@end
