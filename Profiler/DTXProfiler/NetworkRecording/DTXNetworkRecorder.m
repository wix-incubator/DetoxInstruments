//
//  DTXNetworkRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXNetworkRecorder.h"
#import "DTXProfiler-Private.h"
#import "DTXDeviceInfo.h"
@import ObjectiveC;

@interface DTXNetworkRecorder ()

@end

@implementation DTXNetworkRecorder

+ (NSString*)cfNetworkUserAgent
{
	static NSString* ua;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		//StressTestApp/1 CFNetwork/978.0.6 Darwin/18.5.0
		NSMutableString* rv = [NSMutableString new];
		
		NSBundle* bundle = [NSBundle mainBundle];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		[rv appendString:CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(CFAllocatorGetDefault(), CF([bundle objectForInfoDictionaryKey:NS(kCFBundleNameKey)]), NULL, CFSTR("()<>@,;:\"/[]?={}"), kCFStringEncodingUTF8))];
#pragma clang diagnostic pop
		[rv appendFormat:@"/%@ ", [bundle objectForInfoDictionaryKey:NS(kCFBundleVersionKey)]];

		bundle = [NSBundle bundleWithIdentifier:@"com.apple.CFNetwork"];
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		[rv appendString:CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(CFAllocatorGetDefault(), CF([bundle objectForInfoDictionaryKey:NS(kCFBundleNameKey)]), NULL, CFSTR("()<>@,;:\"/[]?={}"), kCFStringEncodingUTF8))];
#pragma clang diagnostic pop
		[rv appendFormat:@"/%@ ", [bundle objectForInfoDictionaryKey:NS(kCFBundleVersionKey)]];
		
		NSDictionary* deviceInfo = DTXDeviceInfo.deviceInfo;
		
		[rv appendFormat:@"%@/%@", deviceInfo[@"kernelName"], deviceInfo[@"kernelVersion"]];
		
		ua = rv;
	});
	
	return ua;
}

+ (void)load
{
	[self cfNetworkUserAgent];
}

@end
