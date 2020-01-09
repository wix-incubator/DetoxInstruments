//
//  AppURLProtocol.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "AppURLProtocol.h"

static NSString *const __AppURLProtocolHandledKey = @"AppURLProtocolHandled";
static NSString *const __AppURLProtocolUniqueIdentifierKey = @"AppURLProtocolUniqueIdentifierKey";

static NSURLSession* __AppURLSession;

@interface AppURLProtocol () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession* urlSession;

@end

@implementation AppURLProtocol

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task
{
	NSURLRequest *request = task.currentRequest;
	return request == nil ? NO : [self canInitWithRequest:request];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
	if ([[self propertyForKey:__AppURLProtocolHandledKey inRequest:request] boolValue]) {
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
	NSLog(@"AppURLProtocol: loading %@", self.request.URL);
	
	NSString* uniqueIdentifier = [NSProcessInfo processInfo].globallyUniqueString;
	NSMutableURLRequest *request = [[AppURLProtocol canonicalRequestForRequest:self.request] mutableCopy];
	
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	[AppURLProtocol setProperty:@YES forKey:__AppURLProtocolHandledKey inRequest:request];
	[AppURLProtocol setProperty:uniqueIdentifier forKey:__AppURLProtocolUniqueIdentifierKey inRequest:request];
	
	if (!self.urlSession) {
		self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
														delegate:self
												   delegateQueue:nil];
	}
	
	[[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		if (error != nil)
		{
			[self.client URLProtocol:self didFailWithError:error];
		}
		
		if (response != nil)
		{
			[self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		}
		
		if (data != nil)
		{
			[self.client URLProtocol:self didLoadData:data];
		}
		
		[self.client URLProtocolDidFinishLoading:self];
	}] resume];
}

- (void)stopLoading {
	// Do nothing
}

@end
