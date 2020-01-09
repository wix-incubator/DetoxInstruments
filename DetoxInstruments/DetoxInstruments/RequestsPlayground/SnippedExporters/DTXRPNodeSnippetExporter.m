//
//  DTXRPNodeSnippetExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRPNodeSnippetExporter.h"

@implementation DTXRPNodeSnippetExporter

+ (NSString*)snippetWithRequest:(NSURLRequest*)request
{
	NSMutableString* rv = @"const https = require('https');\n\n".mutableCopy;
	
	NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
	
	[rv appendString:@"const options = {\n"];
	[rv appendFormat:@"\t'hostname': '%@',\n", urlComponents.host];
	if(urlComponents.port != nil)
	{
		[rv appendFormat:@"\t'port': %@,\n", urlComponents.port];
	}
	[rv appendFormat:@"\t'path': '%@',\n", urlComponents.query.length == 0 ? urlComponents.path : [NSString stringWithFormat:@"%@?%@", urlComponents.path, urlComponents.query]];
	[rv appendFormat:@"\t'method': '%@',\n", request.HTTPMethod];
	[rv appendString:@"\t'headers': {\n"];
	
	__block NSUInteger count = 0;
	[request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		[rv appendFormat:@"\t\t'%@': '%@'", key, obj];
		count++;
		if(count < request.allHTTPHeaderFields.count)
		{
			[rv appendString:@",\n"];
		}
	}];
	
	[rv appendString:@"\n\t}\n};\n\n"];
	
	[rv appendString:@"const request = https.request(options, (response) => {\n"];
	[rv appendString:@"\tconst chunks = [];\n"];
	[rv appendString:@"\tconsole.log(`statusCode: ${response.statusCode}`);\n"];
	[rv appendString:@"\t\n"];
	[rv appendString:@"\tresponse.on('data', (chunk) => {\n"];
	[rv appendString:@"\t\tchunks.push(chunk);\n"];
	[rv appendString:@"\t});\n"];
	[rv appendString:@"\t\n"];
	[rv appendString:@"\tresponse.on('end', (chunk) => {\n"];
	[rv appendString:@"\t\tconst body = Buffer.concat(chunks);\n"];
	[rv appendString:@"\t\tconsole.log(body.toString());\n"];
	[rv appendString:@"\t});\n"];
	[rv appendString:@"});\n"];
	[rv appendString:@"\t\n"];
	[rv appendString:@"request.on('error', (error) => {\n"];
	[rv appendString:@"\tconsole.error(error);\n"];
	[rv appendString:@"});\n"];
	[rv appendString:@"\n"];

	if([request.HTTPMethod isEqualToString:@"GET"] == NO)
	{
		NSString* body = [request.HTTPBody base64EncodedStringWithOptions:0];
		if(body.length > 0)
		{
			[rv appendFormat:@"const base64Data = '%@';\n", body];
			[rv appendString:@"const data = Buffer.from(base64Data, 'base64');\n"];
			[rv appendString:@"request.write(data);\n"];
		}
	}
	
	[rv appendString:@"request.end();\n"];
	
	return rv;
}

@end
