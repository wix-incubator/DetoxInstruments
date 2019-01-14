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

static NSString* _DTXStringFromArray(NSArray* arr)
{
	NSMutableArray* rv = [NSMutableArray new];
	
	[arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[rv addObject:[NSString stringWithFormat:@"\t%@", obj]];
	}];
	
	return [rv componentsJoinedByString:@"\n"];
}

static void _DTXFixupPredicateTimestamps(__kindof NSPredicate* predicate, DTXRecordingDocument* document)
{
	if([predicate isKindOfClass:NSComparisonPredicate.class])
	{
		NSComparisonPredicate* comparison = predicate;
		
		NSLog(@"");
	}
	else if([predicate isKindOfClass:NSCompoundPredicate.class])
	{
		NSCompoundPredicate* compound = predicate;
		[compound.subpredicates enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			_DTXFixupPredicateTimestamps(obj, document);
		}];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"Unsupport predicate type: %@", predicate.className];
	}
}

int main(int argc, const char* argv[])
{
	LNUsageSetIntroStrings(@[@"CLI tools for Detox Instruments"]);
	
	LNUsageSetOptions(@[
						[LNUsageOption optionWithName:@"document" shortcut:@"i" valueRequirement:GBValueRequired description:@"The document"],
						[LNUsageOption optionWithName:@"force" shortcut:@"f" valueRequirement:GBValueNone description:@"Force opening an incompatible recording (data may be lost or the recording damaged altogether)"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"printEntities" shortcut:@"pe" valueRequirement:GBValueNone description:@"Prints available object entities"],
						[LNUsageOption optionWithName:@"entity" shortcut:@"e" valueRequirement:GBValueRequired description:@"The entity to fetch objects of"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"printProperties" shortcut:@"pp" valueRequirement:GBValueNone description:@"Prints available properties for the specified entity"],
						[LNUsageOption optionWithName:@"propertiesToFetch" shortcut:@"pf" valueRequirement:GBValueRequired description:@"A comma-separated collection of properties to fetch (omit to fetch all properties)"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"predicate" shortcut:@"p" valueRequirement:GBValueRequired description:@"The predicate to use for fetching (omit to fetch all objects); timestampts should always be relative"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"fetch" shortcut:@"f" valueRequirement:GBValueNone description:@"Fetch objects of the specified entities, using a predicate if specified"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"dateFormat" shortcut:@"df" valueRequirement:GBValueRequired description:@"The date format to use for displaying timestamps; \"relative\"—Display timestamps relative to the document start (default); \"datetime\"—Display timestamps as absolute dates"],
						[LNUsageOption optionWithName:@"json" valueRequirement:GBValueNone description:@"Export the recording information data as JSON (default)"],
						[LNUsageOption optionWithName:@"plist" valueRequirement:GBValueNone description:@"Export the recording information data as property list"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"version" shortcut:@"v" valueRequirement:GBValueNone description:@"Prints version"],
						]);
	LNUsageSetHiddenOptions(@[[LNUsageOption optionWithName:@"appPath" valueRequirement:GBValueRequired description:@"The “Detox Instruments.app” to use"],
							  ]);
	
	LNUsageSetAdditionalStrings(@[
								  @"",
								  @"For more features, open an issue at https://github.com/wix/DetoxInstruments",
								  @"Pull-requests are always welcome!"
								  ]);
	
	GBSettings* settings = LNUsageParseArguments(argc, argv);
	
	//	LNUsagePrintArguments(LNLogLevelStdOut);
	
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
	
	if([settings boolForKey:@"printEntities"])
	{
		LNLog(LNLogLevelStdOut, @"Available entities:\n%@", _DTXStringFromArray([[model.entities filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isAbstract == NO"]] valueForKey:@"name"]));
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
		
		if([settings boolForKey:@"printProperties"])
		{
			LNLog(LNLogLevelStdOut, @"Available properties for “%@”:\n%@", entityName, _DTXStringFromArray([entity.properties valueForKey:@"name"]));
			return 0;
		}
		
		@try
		{
			NSArray* propertiesToFetch = nil;
			NSString* fpString = [settings objectForKey:@"propertiesToFetch"];
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
			
			if(predicate != nil)
			{
				_DTXFixupPredicateTimestamps(predicate, document);
			}
			
			if([settings boolForKey:@"fetch"])
			{
				NSFetchRequest* fr = [NSFetchRequest new];
				fr.entity = entity;
				fr.propertiesToFetch = propertiesToFetch;
				fr.predicate = predicate;
				[@[@"timestamp", @"startTimestamp"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					if(entity.attributesByName[obj] != nil)
					{
						fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:obj ascending:YES]];
						
						*stop = YES;
					}
				}];
				
				NSError* error;
				NSArray* objs = [document.firstRecording.managedObjectContext executeFetchRequest:fr error:&error];
				
				if(error != nil)
				{
					LNLog(LNLogLevelError, @"Error opening document: %@", error.localizedFailureReason);
					return -1;
				}
				
				NSMutableArray<NSDictionary*>* rvs = [NSMutableArray new];
				
				NSString* conversionType = DTXNSManagedObjectDictionaryRepresentationJSONCallingKey;
				id (^transformer)(NSPropertyDescription* obj, id val) = DTXNSManagedObjectDictionaryRepresentationJSONTransformer;
				NSData* (^converter)(NSArray<NSDictionary*>* objects, NSError** error) = ^ (NSArray<NSDictionary*>* objects, NSError** error) {
					return [NSJSONSerialization dataWithJSONObject:objects options:NSJSONWritingPrettyPrinted error:error];
				};
				
				if([settings boolForKey:@"plist"])
				{
					conversionType = DTXNSManagedObjectDictionaryRepresentationProperyListCallingKey;
					transformer = DTXNSManagedObjectDictionaryRepresentationPropertyListTransformer;
					converter = ^ (NSArray<NSDictionary*>* objects, NSError** error) {
						return [NSPropertyListSerialization dataWithPropertyList:objects format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
					};
				}
				
				if([[settings objectForKey:@"dateFormat"] isEqualToString:@"datetime"] == NO)
				{
					transformer = ^ id (NSPropertyDescription* obj, id val) {
						if([obj.name rangeOfString:@"timestamp" options:NSCaseInsensitiveSearch].location != NSNotFound)
						{
							val = @([(NSDate*)val timeIntervalSinceDate:document.firstRecording.startTimestamp]);
						}
						else
						{
							val = transformer(obj, val);
						}
						
						return val;
					};
				}
				
				[objs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					NSDictionary* rvObj = DTXNSManagedObjectDictionaryRepresentation(obj, entity, propertiesToFetch, transformer, conversionType, NO, YES);
					[rvs addObject:rvObj];
				}];
				
				NSData* convertedData = converter(rvs, &error);
				if(error != nil)
				{
					LNLog(LNLogLevelError, @"Error converting objects for output: %@", error);
					return -1;
				}
				
				LNLog(LNLogLevelStdOut, @"%@", [[NSString alloc] initWithData:convertedData encoding:NSUTF8StringEncoding]);
				
				return 0;
			}
			
			LNUsagePrintMessage(@"No action specified", LNLogLevelError);
			return -1;
		}
		@catch(NSException* exception)
		{
			LNLog(LNLogLevelError, @"Error fetching objects: %@", exception.reason);
			return -1;
		}
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
