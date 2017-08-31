//
//  DTXURLProtocol.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTXURLProtocol;

extern NSString *const DTXURLProtocolHandledKey;

@protocol DTXURLProtocolDelegate <NSObject>

- (void)urlProtocol:(NSURLProtocol*)protocol didStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier;
- (void)urlProtocol:(NSURLProtocol*)protocol didFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier;

@end

@interface DTXURLProtocol : NSURLProtocol

@property (nonatomic, weak, class) id<DTXURLProtocolDelegate> delegate;

@end
