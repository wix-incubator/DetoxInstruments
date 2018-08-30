//
//  main.m
//  Helper
//
//  Created by Leo Natan (Wix) on 11/20/17.
//  Copyright © 2017 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRecordingDocumentController.h"
#import "DTXRecordingDocument.h"
#import "LNOptionsParser.h"

int main(int argc, const char* argv[])
{
	@autoreleasepool
	{
		LNUsageSetIntroStrings(@[@"Helper tool for DetoxInstruments"]);
		
		LNUsageSetOptions(@[
							[LNUsageOption optionWithName:@"input" valueRequirement:GBValueRequired description:@""],
							[LNUsageOption optionWithName:@"output" valueRequirement:GBValueRequired description:@""],
							[LNUsageOption optionWithName:@"json" valueRequirement:GBValueNone description:@""],
							[LNUsageOption optionWithName:@"plist" valueRequirement:GBValueNone description:@""],
							]);
		
		GBSettings* settings = LNUsageParseArguments(argc, argv);
		
		auto documentController = [DTXRecordingDocumentController new];
		
		auto inputURL = [NSURL fileURLWithPath:[settings objectForKey:@"input"]];
		NSURL* outputDirURL;
		if([settings objectForKey:@"output"] != nil)
		{
			outputDirURL = [NSURL fileURLWithPath:[settings objectForKey:@"output"]];
			if(outputDirURL.hasDirectoryPath == NO)
			{
				outputDirURL = outputDirURL.URLByDeletingLastPathComponent;
			}
		}
		else
		{
			outputDirURL = inputURL.URLByDeletingLastPathComponent;
		}
		
		@autoreleasepool
		{
			NSError* error;
			DTXRecordingDocument* document = [documentController makeDocumentWithContentsOfURL:inputURL ofType:@"dtxprof" error:&error];
			
			if([settings boolForKey:@"json"])
			{
				NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[document.recordings valueForKey:@"cleanDictionaryRepresentationForJSON"] options:NSJSONWritingPrettyPrinted error:&error];
				NSURL* jsonURL = [outputDirURL URLByAppendingPathComponent:[inputURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"json"]];
				[jsonData writeToURL:jsonURL atomically:YES];
			}
			
			if([settings boolForKey:@"plist"])
			{
				NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:[document.recordings valueForKey:@"cleanDictionaryRepresentationForPropertyList"] format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
				NSURL* plistURL = [outputDirURL URLByAppendingPathComponent:[inputURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"plist"]];
				[plistData writeToURL:plistURL atomically:YES];
			}
		}
	}
	return 0;
}
