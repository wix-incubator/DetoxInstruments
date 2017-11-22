//
//  main.m
//  Helper
//
//  Created by Leo Natan (Wix) on 11/20/17.
//  Copyright © 2017 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXDocumentController.h"
#import "DTXDocument.h"

int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		auto documentController = [DTXDocumentController new];
		
		auto inputURL = [NSURL fileURLWithPath:NSProcessInfo.processInfo.arguments.lastObject];
		
		NSError* error;
		DTXDocument* document = [documentController makeDocumentWithContentsOfURL:inputURL ofType:@"dtxprof" error:&error];
		
		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:document.recording.dictionaryRepresentationForJSON options:NSJSONWritingPrettyPrinted error:NULL];
		NSURL* jsonURL = [inputURL URLByAppendingPathComponent:@"_dtx_recording.json"];
		[jsonData writeToURL:jsonURL atomically:YES];
		
		NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:document.recording.dictionaryRepresentationForPropertyList format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
		NSURL* plistURL = [inputURL URLByAppendingPathComponent:@"_dtx_recording.plist"];
		[plistData writeToURL:plistURL atomically:YES];
	}
	return 0;
}
