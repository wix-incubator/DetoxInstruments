//
//  DTXRPNodeSnippetExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
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
	
	[rv appendString:@"const request = https.request(options, (response) => {\n\
\tconst chunks = [];\n\
\tconsole.log(`statusCode: ${response.statusCode}`);\n\
\t\n\
\tresponse.on('data', (chunk) => {\n\
\t\tchunks.push(chunk);\n\
\t});\n\
\t\n\
\tresponse.on('end', (chunk) => {\n\
\t\tconst body = Buffer.concat(chunks);\n\
\t\tconsole.log(body.toString());\n\
\t});\n\
});\n\
\t\n\
request.on('error', (error) => {\n\
\tconsole.error(error);\n\
});\n\
\n"];
	
	if([request.HTTPMethod isEqualToString:@"GET"] == NO)
	{
		NSString* body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
		if(body.length > 0)
		{
			[rv appendFormat:@"const data = '%@';\n", [[body stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
			[rv appendString:@"request.write(data);\n"];
		}
	}
	
	[rv appendString:@"request.end();\n"];
	
	return rv;
}

@end
