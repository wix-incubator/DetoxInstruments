//
//  DTXRPCurlSnippetExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRPCurlSnippetExporter.h"

@implementation DTXRPCurlSnippetExporter

+ (NSString*)snippetWithRequest:(NSURLRequest*)request
{
	NSMutableString* rv = @"curl ".mutableCopy;
	
	if([request.HTTPMethod isEqualToString:@"GET"] == NO)
	{
		[rv appendFormat:@"-X %@ ", request.HTTPMethod];
		
		NSString* body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
		if(body.length > 0)
		{
			[rv appendFormat:@"--data-binary '%@' ", [body stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
		}
	}
	
	[request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		[rv appendFormat:@"-H '%@: %@' ", key, obj];
	}];
	
	[rv appendString:request.URL.absoluteString];
	
	return rv;
}

@end
