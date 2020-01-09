//
//  DTXPollingManager.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPollable.h"

typedef void (^DTXPollableHandler)(id<DTXPollable> pollable);

@interface DTXPollingManager : NSObject

- (instancetype)initWithInterval:(NSTimeInterval)timeInterval NS_DESIGNATED_INITIALIZER;

- (void)addPollable:(id<DTXPollable>)pollable handler:(DTXPollableHandler)handler;


- (void)resume;
- (void)suspend;

@end
