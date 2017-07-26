//
//  DTXRemoteProfilingTarget.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXSocketConnection.h"

@interface DTXRemoteProfilingTarget : NSObject

@property (nonatomic, assign, readonly) NSUInteger operatingSystemType;
@property (nonatomic, copy, readonly) NSString* applicationName;
@property (nonatomic, copy, readonly) NSString* deviceName;
@property (nonatomic, copy, readonly) NSString* operatingSystemVersion;

@property (nonatomic, copy, readonly) NSString* hostName;
@property (nonatomic, assign, readonly) NSInteger port;

@property (nonatomic, strong, readonly) DTXSocketConnection* connection;

@end
