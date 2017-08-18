//
//  DTXRemoteProfilingTarget-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteProfilingTarget.h"
#import "DTXSocketConnection.h"

@interface DTXRemoteProfilingTarget ()

@property (nonatomic, assign, readwrite) NSUInteger deviceOSType;
@property (nonatomic, copy, readwrite) NSString* appName;
@property (nonatomic, copy, readwrite) NSString* deviceName;
@property (nonatomic, copy, readwrite) NSString* deviceOS;
@property (nonatomic, copy, readwrite) NSImage* deviceSnapshot;
@property (nonatomic, copy, readwrite) NSDictionary* deviceInfo;

@property (nonatomic, copy, readonly) NSString* hostName;
@property (nonatomic, assign, readonly) NSInteger port;
@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;

- (void)_connectWithHostName:(NSString*)hostName port:(NSInteger)port workQueue:(dispatch_queue_t)workQueue;

@end
