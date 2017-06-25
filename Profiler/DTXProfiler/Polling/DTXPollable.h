//
//  DTXPollable.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@protocol DTXPollable <NSObject>

- (void)pollWithTimePassed:(NSTimeInterval)interval;

@end
