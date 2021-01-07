//
//  DTXRPCurlSnippetExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXRPCurlSnippetExporter.h"

@implementation DTXRPCurlSnippetExporter

+ (NSString*)snippetWithRequest:(NSURLRequest*)request
{
	NSMutableString* rv = [NSMutableString new];
	
	NSString* body = nil;
	if([request.HTTPMethod isEqualToString:@"GET"] == NO)
	{
		body = [request.HTTPBody base64EncodedStringWithOptions:0];
		if(body.length > 0)
		{
			[rv appendFormat:@"echo '%@' | base64 --decode | ", [body stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
		}
	}

	[rv appendFormat:@"curl -X %@ ", request.HTTPMethod];
	
	[request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		[rv appendFormat:@"-H '%@: %@' ", key, obj];
	}];
	
	if(body.length > 0)
	{
		[rv appendString:@"-d @- "];
	}
	
	if(request.URL != nil)
	{
		[rv appendString:request.URL.absoluteString];
	}
	else
	{
		[rv appendString:@"<url>"];
	}
	
	return rv;
}

@end
