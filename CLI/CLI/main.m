//
//  main.m
//  Helper
//
//  Created by Leo Natan (Wix) on 11/20/17.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRecordingDocument.h"
#import "LNOptionsParser.h"
#import "DTXInstrumentsModel.h"
#import "DTXInstrumentsModelUIExtensions.h"

static char* const __version =
#include "version.h"
;

NSString* _DTXStringFromArray(NSArray* arr)
{
	NSMutableArray* rv = [NSMutableArray new];
	
	[arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[rv addObject:[NSString stringWithFormat:@"\t%@", obj]];
	}];
	
	return [rv componentsJoinedByString:@"\n"];
}

int main(int argc, const char* argv[])
{
	LNUsageSetIntroStrings(@[@"CLI tools for Detox Instruments"]);
	
	LNUsageSetOptions(@[
						[LNUsageOption optionWithName:@"document" shortcut:@"i" valueRequirement:GBValueRequired description:@"The document"],
						[LNUsageOption optionWithName:@"force" shortcut:nil valueRequirement:GBValueNone description:@"Force opening an incompatible recording (data may be lost or the recording damaged altogether)"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"print-entities" shortcut:@"pe" valueRequirement:GBValueNone description:@"Prints available object entities"],
						[LNUsageOption optionWithName:@"entity" shortcut:@"e" valueRequirement:GBValueRequired description:@"The entity to fetch objects of"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"print-properties" shortcut:@"pp" valueRequirement:GBValueNone description:@"Prints available properties for the specified entity"],
						[LNUsageOption optionWithName:@"fetched-properties" shortcut:@"fp" valueRequirement:GBValueRequired description:@"A comma-separated collection of properties to fetch (omit to fetch all properties)"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"predicate" shortcut:@"p" valueRequirement:GBValueRequired description:@"The predicate to use for fetching (omit to fetch all objects)"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"fetch" shortcut:@"f" valueRequirement:GBValueNone description:@"Fetch objects of the specified entities, using a predicate if specified"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"json" valueRequirement:GBValueNone description:@"Export the recording information data as JSON"],
						[LNUsageOption optionWithName:@"plist" valueRequirement:GBValueNone description:@"Export the recording information data as property list"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"version" shortcut:@"v" valueRequirement:GBValueNone description:@"Prints version"],
						]);
	
	LNUsageSetAdditionalStrings(@[
								  @"",
								  @"For more features, open an issue at https://github.com/wix/DetoxInstruments",
								  @"Pull-requests are always welcome!"
								  ]);
	
	GBSettings* settings = LNUsageParseArguments(argc, argv);
	
	NSLog(@"%@", [NSProcessInfo.processInfo.arguments componentsJoinedByString:@" "]);
	
	if([settings boolForKey:@"version"])
	{
		LNLog(LNLogLevelStdOut, @"%@ version %s", NSProcessInfo.processInfo.arguments.firstObject.lastPathComponent, __version);
		return 0;
	}
	
	if([settings objectForKey:@"document"] == nil)
	{
		LNUsagePrintMessage(@"No document argument specified", LNLogLevelError);
		
		return -1;
	}
	
	auto inputURL = [NSURL fileURLWithPath:[settings objectForKey:@"document"]];
	
	NSError* error;
	DTXRecordingDocument* document = [[DTXRecordingDocument alloc] initWithContentsOfURL:inputURL ofType:@"dtxprof" error:&error];
	
	if(error != nil)
	{
		LNLog(LNLogLevelError, @"Error opening document: %@", error.localizedFailureReason);
		return -1;
	}
	
	NSManagedObjectModel* model = document.firstRecording.entity.managedObjectModel;
	
	if([settings boolForKey:@"print-entities"])
	{
		LNLog(LNLogLevelStdOut, @"Available entities:\n%@", _DTXStringFromArray([model.entities valueForKey:@"name"]));
		return 0;
	}
	
	NSString* entityName = [settings objectForKey:@"entity"];
	if(entityName)
	{
		NSEntityDescription* entity = model.entitiesByName[entityName];
		
		if(entity == nil)
		{
			LNLog(LNLogLevelError, @"Unknown entity “%@”", entityName);
			return -1;
		}
		
		if([settings boolForKey:@"print-properties"])
		{
			LNLog(LNLogLevelStdOut, @"Available properties for “%@”:\n%@", entityName, _DTXStringFromArray([entity.properties valueForKey:@"name"]));
			return 0;
		}
		
		NSArray* propertiesToFetch = nil;
		NSString* fpString = [settings objectForKey:@"fetched-properties"];
		if(fpString)
		{
			NSMutableArray* arr = [NSMutableArray new];
			[[fpString componentsSeparatedByString:@","] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				[arr addObject:[obj stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
			}];
			propertiesToFetch = arr;
		}
		
		NSPredicate* predicate = nil;
		NSString* predicateString = [settings objectForKey:@"predicate"];
		if(predicateString != nil)
		{
			predicate = [NSPredicate predicateWithFormat:predicateString argumentArray:nil];
		}
		
		if([settings boolForKey:@"fetch"])
		{
			@try
			{
				NSFetchRequest* fr = [NSFetchRequest new];
				fr.entity = entity;
				fr.propertiesToFetch = propertiesToFetch;
				fr.predicate = predicate;
				
				NSError* error;
				NSArray* objs = [document.firstRecording.managedObjectContext executeFetchRequest:fr error:&error];
				
				if(error != nil)
				{
					LNLog(LNLogLevelError, @"Error opening document: %@", error.localizedFailureReason);
					return -1;
				}
				
				NSMutableArray<NSDictionary*>* rvs = [NSMutableArray new];
				
				[objs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					NSDictionary* rvObj = DTXNSManagedObjectDictionaryRepresentation(obj, entity, propertiesToFetch, nil, DTXNSManagedObjectDictionaryRepresentationProperyListCallingKey, NO);
					[rvs addObject:rvObj];
				}];
				
				NSLog(@"%@", rvs);
			}
			@catch(NSException* exception)
			{
				LNLog(LNLogLevelError, @"Error fetching objects: %@", exception.reason);
				return -1;
			}
			
			return 0;
		}
		
		LNUsagePrintMessage(@"No action specified", LNLogLevelError);
		return -1;
	}
	
	LNUsagePrintMessage(@"No entity specified", LNLogLevelError);
		
//	if([settings boolForKey:@"json"])
//	{
//		NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[document.recordings valueForKey:@"cleanDictionaryRepresentationForJSON"] options:NSJSONWritingPrettyPrinted error:&error];
//		NSURL* jsonURL = [outputDirURL URLByAppendingPathComponent:[inputURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"json"]];
//		[jsonData writeToURL:jsonURL atomically:YES];
//	}
//
//	if([settings boolForKey:@"plist"])
//	{
//		NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:[document.recordings valueForKey:@"cleanDictionaryRepresentationForPropertyList"] format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
//		NSURL* plistURL = [outputDirURL URLByAppendingPathComponent:[inputURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"plist"]];
//		[plistData writeToURL:plistURL atomically:YES];
//	}
	
	return 0;
}
