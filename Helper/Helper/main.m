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
#import "LNOptionsParser.h"

int main(int argc, const char* argv[])
{
	@autoreleasepool
	{
		LNUsageSetIntroStrings(@[@"Helper tool for DetoxInstruments"]);
		
		/*
		 [parser registerOption:@"input" requirement:GBValueRequired];
		 [parser registerOption:@"output" requirement:GBValueRequired];
		 [parser registerOption:@"json" requirement:GBValueNone];
		 [parser registerOption:@"plist" requirement:GBValueNone];
		 */
		
		LNUsageSetOptions(@[
							[LNUsageOption optionWithName:@"input" valueRequirement:GBValueRequired description:@""],
							[LNUsageOption optionWithName:@"output" valueRequirement:GBValueRequired description:@""],
							[LNUsageOption optionWithName:@"json" valueRequirement:GBValueNone description:@""],
							[LNUsageOption optionWithName:@"plist" valueRequirement:GBValueNone description:@""],
							]);
		
		GBSettings* settings = LNUsageParseArguments(argc, argv);
		
		auto documentController = [DTXDocumentController new];
		
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
		
		NSError* error;
		DTXDocument* document = [documentController makeDocumentWithContentsOfURL:inputURL ofType:@"dtxprof" error:&error];
		
		if([settings boolForKey:@"json"])
		{
			NSData* jsonData = [NSJSONSerialization dataWithJSONObject:document.recording.dictionaryRepresentationForJSON options:NSJSONWritingPrettyPrinted error:NULL];
			NSURL* jsonURL = [outputDirURL URLByAppendingPathComponent:[inputURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"json"]];
			[jsonData writeToURL:jsonURL atomically:YES];
		}
		
		if([settings boolForKey:@"plist"])
		{
			NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:document.recording.dictionaryRepresentationForPropertyList format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
			NSURL* plistURL = [outputDirURL URLByAppendingPathComponent:[inputURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"plist"]];
			[plistData writeToURL:plistURL atomically:YES];
		}
	}
	return 0;
}
