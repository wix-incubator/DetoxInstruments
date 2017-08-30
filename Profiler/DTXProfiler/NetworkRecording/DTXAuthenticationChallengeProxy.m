//
//  DTXAuthenticationChallengeProxy.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXAuthenticationChallengeProxy.h"

@interface DTXAuthenticationChallengeProxy()

@property (nonatomic, copy) void (^sessionCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential);

@end

@implementation DTXAuthenticationChallengeProxy

#pragma mark - Initialization

- (instancetype)initWithSessionCompletionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))sessionCompletionHandler
{
	self = [super init];
	if (self) {
		self.sessionCompletionHandler = sessionCompletionHandler;
	}
	
	return self;
}

+ (instancetype)authenticationChallengeSenderWithSessionCompletionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))sessionCompletionHandler;
{
	return [[self alloc] initWithSessionCompletionHandler:sessionCompletionHandler];
}

#pragma mark - NSURLAuthenticationChallengeSender

- (void)useCredential:(NSURLCredential *)credential forAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if (self.sessionCompletionHandler) {
		self.sessionCompletionHandler(NSURLSessionAuthChallengeUseCredential, credential);
	}
}

- (void)continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if (self.sessionCompletionHandler) {
		self.sessionCompletionHandler(NSURLSessionAuthChallengeUseCredential, nil);
	}
}

- (void)cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge; {
	if (self.sessionCompletionHandler) {
		self.sessionCompletionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
	}
}

- (void)performDefaultHandlingForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if (self.sessionCompletionHandler) {
		self.sessionCompletionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
	}
}

- (void)rejectProtectionSpaceAndContinueWithChallenge:(NSURLAuthenticationChallenge *)challenge {
	if (self.sessionCompletionHandler) {
		self.sessionCompletionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
	}
}

@end
