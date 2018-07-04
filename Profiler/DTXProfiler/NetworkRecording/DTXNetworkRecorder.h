//
//  DTXNetworkRecorder.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DTXNetworkProfilingListener <NSObject>
- (void)networkRecorderDidStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)netwrokRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier;
@end

@interface DTXNetworkRecorder : NSObject

+ (BOOL)hasNetworkListeners;
+ (void)addNetworkListener:(id<DTXNetworkProfilingListener>)listener;
+ (void)removeNetworkListener:(id<DTXNetworkProfilingListener>)listener;

@end
