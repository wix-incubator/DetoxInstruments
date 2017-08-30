//
//  DTXAuthenticationChallengeProxy.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `DTXAuthenticationChallengeProxy` is a proxy object responsible for calling the `NSURLSession` completion handler.
 */
@interface DTXAuthenticationChallengeProxy : NSObject <NSURLAuthenticationChallengeSender>

/**
 Creates and returns a new instance of `DTXAuthenticationChallengeProxy` with a given session completion handler.
 
 @param sessionCompletionHandler The block passed to `NSURLSessionDelegate`.
 */
+ (instancetype)authenticationChallengeSenderWithSessionCompletionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))sessionCompletionHandler;

@end
