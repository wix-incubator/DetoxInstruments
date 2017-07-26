//
//  DTXRemoteProfilingTarget-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteProfilingTarget.h"

@interface DTXRemoteProfilingTarget ()

@property (nonatomic, assign) NSUInteger state;

@property (nonatomic, assign, readwrite) NSUInteger operatingSystemType;
@property (nonatomic, copy, readwrite) NSString* applicationName;
@property (nonatomic, copy, readwrite) NSString* deviceName;
@property (nonatomic, copy, readwrite) NSString* operatingSystemVersion;

@property (nonatomic, copy, readwrite) NSString* hostName;
@property (nonatomic, assign, readwrite) NSInteger port;

@property (nonatomic, strong, readwrite) DTXSocketConnection* connection;

@end
