//
//  DTXNetworkRecorder.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTXNetworkRecorder;

@protocol DTXNetworkListener <NSObject>
- (void)networkRecorderDidStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)netwrokRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier;
@end

@interface DTXNetworkRecorder : NSObject

+ (void)addNetworkListener:(id<DTXNetworkListener>)listener;
+ (void)removeNetworkListener:(id<DTXNetworkListener>)listener;

@end
