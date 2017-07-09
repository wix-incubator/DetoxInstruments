//
//  DTXSample+Additions.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSample+CoreDataClass.h"
#import "DTXRecording+Additions.h"

@interface DTXSample (Additions)

@property (nonatomic, strong, readonly) DTXRecording* recording;

@end
