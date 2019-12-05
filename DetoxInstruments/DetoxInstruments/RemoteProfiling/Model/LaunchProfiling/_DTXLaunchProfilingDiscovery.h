//
//  _DTXLaunchProfilingDiscovery.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/1/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTXRemoteTarget;

@interface _DTXLaunchProfilingDiscovery : NSObject

- (instancetype)initWithSessionID:(NSString*)session completionHandler:(void(^)(DTXRemoteTarget* target))completionHandler;
- (void)stop;

@end
