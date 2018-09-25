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

static char* const __version =
#include "version.h"
;

int main(int argc, const char* argv[])
{
	@autoreleasepool
	{
		LNUsageSetIntroStrings(@[@"CLI tools for Detox Instruments"]);
		
		LNUsageSetOptions(@[
							[LNUsageOption optionWithName:@"input" shortcut:@"i" valueRequirement:GBValueRequired description:@"The input recording"],
							[LNUsageOption optionWithName:@"output" shortcut:@"o" valueRequirement:GBValueRequired description:@"The output directory"],
							[LNUsageOption optionWithName:@"json" valueRequirement:GBValueNone description:@"Export the recording information data as JSON"],
							[LNUsageOption optionWithName:@"plist" valueRequirement:GBValueNone description:@"Export the recording information data as property list"],
							[LNUsageOption optionWithName:@"version" shortcut:@"v" valueRequirement:GBValueNone description:@"Prints version"],
							]);
		
		LNUsageSetAdditionalStrings(@[
									  @"",
									  @"For more features, open an issue at https://github.com/wix/DetoxInstruments",
									  @"Pull-requests are always welcome!"
									  ]);
		
		GBSettings* settings = LNUsageParseArguments(argc, argv);
		
		if([settings boolForKey:@"version"])
		{
			LNLog(LNLogLevelStdOut, @"%@ version %s", NSProcessInfo.processInfo.arguments.firstObject.lastPathComponent, __version);
			return 0;
		}
		
		if(![settings boolForKey:@"version"] &&
		   (
			![settings objectForKey:@"input"] ||
			![settings objectForKey:@"output"] ||
			(
			 ![settings boolForKey:@"json"] &&
			 ![settings boolForKey:@"plist"])
			)
		   )
		{
			LNUsagePrintMessage(nil, LNLogLevelStdOut);
			exit(-1);
		}
		
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
