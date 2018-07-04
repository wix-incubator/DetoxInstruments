//
//  DTXURLProtocol.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXURLProtocol.h"
#import "DTXAuthenticationChallengeProxy.h"
@import ObjectiveC;
#import "DTXExternalProtocolHooking.h"
#import "DTXNetworkRecorder.h"

NSString *const DTXURLProtocolHandledKey = @"DTXURLProtocolHandled";
static NSString *const DTXURLProtocolUniqueIdentifierKey = @"DTXURLProtocolUniqueIdentifierKey";
static __weak id<DTXURLProtocolDelegate> __protocolDelelgate;

@interface DTXURLProtocol () <NSURLSessionDelegate, _DTXUserProtocolIsSwizzled>

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation DTXURLProtocol

+ (id<DTXURLProtocolDelegate>)delegate
{
	return __protocolDelelgate;
}

+ (void)setDelegate:(id<DTXURLProtocolDelegate>)delegate
{
	__protocolDelelgate = delegate;
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task
{
	NSURLRequest *request = task.currentRequest;
	return request == nil ? NO : [self canInitWithRequest:request];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
	if([DTXNetworkRecorder hasNetworkListeners] == NO)
	{
		return NO;
	}
	
	//TODO: More logic needed
	
	if ([[self propertyForKey:DTXURLProtocolHandledKey inRequest:request] boolValue])
	{
		return NO;
	}
	
	if([request.URL.scheme isEqualToString:@"data"])
	{
		return NO;
	}
	
	return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
	return request;
}

- (void)startLoading
{
	NSString* uniqueIdentifier = [NSProcessInfo processInfo].globallyUniqueString;
	NSMutableURLRequest *request = [[DTXURLProtocol canonicalRequestForRequest:self.request] mutableCopy];
	
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	[DTXURLProtocol setProperty:@YES forKey:DTXURLProtocolHandledKey inRequest:request];
	[DTXURLProtocol setProperty:uniqueIdentifier forKey:DTXURLProtocolUniqueIdentifierKey inRequest:request];
	
	[DTXURLProtocol.delegate urlProtocol:self didStartRequest:request uniqueIdentifier:uniqueIdentifier];
	
	if (!self.urlSession) {
		self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
	}
	
	[[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		if (error != nil)
		{
			__orig_URLProtocol_didFailWithError(self.client, @selector(URLProtocol:didFailWithError:), self, error);
		}
		
		if (response != nil)
		{
			__orig_URLProtocol_didReceiveResponse_cacheStoragePolicy(self.client, @selector(URLProtocol:didReceiveResponse:cacheStoragePolicy:), self, response, NSURLCacheStorageNotAllowed);
		}
		
		if (data != nil)
		{
			__orig_URLProtocol_didLoadData(self.client, @selector(URLProtocol:didLoadData:), self, data);
		}
		
		[DTXURLProtocol.delegate urlProtocol:self didFinishWithResponse:response data:data error:error forRequestWithUniqueIdentifier:uniqueIdentifier];
		
		__orig_URLProtocolDidFinishLoading(self.client, @selector(URLProtocolDidFinishLoading:), self);
	}] resume];
}

- (void)stopLoading {
	// Do nothing
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
	DTXAuthenticationChallengeProxy *challengeSender = [DTXAuthenticationChallengeProxy authenticationChallengeSenderWithSessionCompletionHandler:completionHandler];
	NSURLAuthenticationChallenge *modifiedChallenge = [[NSURLAuthenticationChallenge alloc] initWithAuthenticationChallenge:challenge sender:challengeSender];
	[self.client URLProtocol:self didReceiveAuthenticationChallenge:modifiedChallenge];
}

@end
