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

#define DTXAssert(condition, desc, ...) \
do { \
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (__builtin_expect(!(condition), 0)) { \
[NSException raise:NSInvalidArgumentException format:(desc), ##__VA_ARGS__]; \
} \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0)

static NSString* _DTXStringFromArray(NSArray* arr)
{
	NSMutableArray* rv = [NSMutableArray new];
	
	[arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[rv addObject:[NSString stringWithFormat:@"\t%@", obj]];
	}];
	
	return [rv componentsJoinedByString:@"\n"];
}

#define FIX_TIMESTAMP_IF_NEEDED(firstExpression, secondExpression) if(predicate.firstExpression.keyPath != nil && [predicate.firstExpression.keyPath rangeOfString:@"timestamp" options:NSCaseInsensitiveSearch].location != NSNotFound) \
{ \
DTXAssert([predicate.secondExpression.constantValue isKindOfClass:NSNumber.class], @"rhs of “%@” expression must be a numeric constant", predicate); \
auto keyPathExpression = predicate.firstExpression; \
auto constantExpression = [NSExpression expressionForConstantValue:[document.firstRecording.startTimestamp dateByAddingTimeInterval:[predicate.secondExpression.constantValue doubleValue]]]; \
BOOL isKPLHS = predicate.leftExpression == predicate.firstExpression; \
return [[NSComparisonPredicate alloc] initWithLeftExpression: isKPLHS ? keyPathExpression : constantExpression rightExpression: isKPLHS ? constantExpression : keyPathExpression modifier:predicate.comparisonPredicateModifier type:predicate.predicateOperatorType options:predicate.options]; \
} \

static NSComparisonPredicate* _DTXFixupTimestampForPredicate(NSComparisonPredicate* predicate, DTXRecordingDocument* document)
{
	FIX_TIMESTAMP_IF_NEEDED(leftExpression, rightExpression);
	FIX_TIMESTAMP_IF_NEEDED(rightExpression, leftExpression);
	
	return predicate;
}

static __kindof NSPredicate* _DTXFixupPredicateTimestamps(__kindof NSPredicate* predicate, DTXRecordingDocument* document)
{
	if([predicate isKindOfClass:NSComparisonPredicate.class])
	{
		NSComparisonPredicate* comparison = predicate;
		
		return _DTXFixupTimestampForPredicate(comparison, document);
	}
	else if([predicate isKindOfClass:NSCompoundPredicate.class])
	{
		NSCompoundPredicate* compound = predicate;
		NSMutableArray* newSubpredicates = [NSMutableArray new];
		[compound.subpredicates enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[newSubpredicates addObject:_DTXFixupPredicateTimestamps(obj, document)];
		}];
		
		return [[NSCompoundPredicate alloc] initWithType:compound.compoundPredicateType subpredicates:newSubpredicates];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"Unsupport predicate type: %@", predicate.className];
		
		return nil;
	}
}

NSString* _DTXStringFromAttributeType(NSAttributeDescription* attributeDescription)
{
	switch (attributeDescription.attributeType)
	{
		case NSUndefinedAttributeType:
			return @"undefined";
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
		case NSDecimalAttributeType:
		case NSDoubleAttributeType:
		case NSFloatAttributeType:
			return @"number";
		case NSStringAttributeType:
			return @"string";
		case NSBooleanAttributeType:
			return @"boolean";
		case NSDateAttributeType:
			return @"date";
		case NSBinaryDataAttributeType:
			return @"binary data";
		case NSUUIDAttributeType:
			return @"UUID";
		case NSURIAttributeType:
			return @"URI";
		case NSTransformableAttributeType:
		{
			NSMutableString* className = attributeDescription.attributeValueClassName.mutableCopy;
			[className replaceOccurrencesOfString:@"NS" withString:@"" options:0 range:NSMakeRange(0, className.length)];
			[className replaceOccurrencesOfString:@"DTX" withString:@"" options:0 range:NSMakeRange(0, className.length)];
			
			return className.lowercaseString;
		}
		case NSObjectIDAttributeType:
			return @"object ID";
	}
}

void _DTXPrintProperties(NSEntityDescription* entity)
{
	NSMutableArray* properties = [NSMutableArray new];
	NSMutableArray* additional = [NSMutableArray new];
	
	[entity.properties enumerateObjectsUsingBlock:^(__kindof NSPropertyDescription * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
	 {
		 BOOL isRelationship = NO, isRToMany = NO;
		 NSString* destinationEntityName = nil;
		 NSString* propertyType = nil;
		 
		 if(([obj isKindOfClass:NSFetchedPropertyDescription.class] || [obj isKindOfClass:NSRelationshipDescription.class]) && [obj.userInfo[@"includeInDictionaryRepresentation"] boolValue] == NO)
		 {
			 return;
		 }
		 
		 if([obj isKindOfClass:NSFetchedPropertyDescription.class])
		 {
			 NSFetchedPropertyDescription* fp = obj;
			 
			 isRelationship = YES;
			 isRToMany = YES;
			 destinationEntityName = fp.fetchRequest.entityName;
		 }
		 else if([obj isKindOfClass:NSRelationshipDescription.class])
		 {
			 NSRelationshipDescription* rel = obj;
			 
			 isRelationship = YES;
			 isRToMany = rel.isToMany;
			 destinationEntityName = rel.destinationEntity.name;
		 }
		 else if([obj isKindOfClass:NSAttributeDescription.class])
		 {
			 NSAttributeDescription* attr = obj;
			 
			 propertyType = _DTXStringFromAttributeType(attr);
		 }
		 
		 [properties addObject:obj.name];
		 [additional addObject:!isRelationship ? [NSString stringWithFormat:@"%@", propertyType] : [NSString stringWithFormat:@"%@, entity: %@", isRToMany ? @"relationship: one-to-many" : @"relationship: one-to-one", destinationEntityName]];
	 }];
	
	NSUInteger longestPropertyName = [[properties valueForKeyPath:@"@max.length"] unsignedIntegerValue];
	NSMutableArray* rv = [NSMutableArray new];
	
	[additional enumerateObjectsUsingBlock:^(NSString* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[rv addObject:[NSString stringWithFormat:@"%@ %@", [properties[idx] stringByPaddingToLength:longestPropertyName + 3 withString:@" " startingAtIndex:0], obj]];
	}];
	
	[rv sortUsingSelector:@selector(compare:)];
	
	LNLog(LNLogLevelStdOut, @"“%@” keys:\n%@", entity.name, _DTXStringFromArray(rv));
}

BOOL _DTXParseFunction(NSString* expr, NSString** functionName, NSString** function, NSString** keyPath)
{
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"([[:alnum:]]*)\\(([[:alnum:]]*)\\)" options:NSRegularExpressionAnchorsMatchLines error:NULL];
	NSArray* matches = [regex matchesInString:expr options:0 range:NSMakeRange(0, expr.length)];
	
	if(matches.count > 0)
	{
		NSTextCheckingResult* match = matches.firstObject;
		*functionName = [expr substringWithRange:[match rangeAtIndex:1]];
		*function = [NSString stringWithFormat:@"%@:", *functionName];
		*keyPath = [expr substringWithRange:[match rangeAtIndex:2]];
		
		return YES;
	}
	
	return NO;
}

int main(int argc, const char* argv[])
{
	LNUsageSetIntroStrings(@[@"CLI tool for Detox Instruments"]);
	
	LNUsageSetExampleStrings(@[
							   @"%@ --document MyRecording.dtxrec --printEntities",
							   @"%@ -d MyRecording.dtxrec --entity Recording --printKeys",
							   @"%@ -d MyRecording.dtxrec -e Recording --keys \"appName,deviceName,startTimestamp,endTimestamp\" --fetch --dateFormat datetime",
							   @"%@ -d MyRecording.dtxrec -e PerformanceSample -k \"cpuUsage,memoryUsage,fps,timestamp\" --predicate \"timestamp >= 15 && timestamp <= 30\" -f",
							   @"%@ -d MyRecording.dtxrec -e PerformanceSample -k \"average(cpuUsage),min(memoryUsage),max(memoryUsage)\" -p \"timestamp >= 15 && timestamp <= 30\" --limit 1 -f",
							   @"%@ -d MyRecording.dtxrec -e NetworkSample -k \"url,responseError\" -p \"responseStatusCode != 200\" -f",
							   ]);
	
	LNUsageSetOptions(@[
						[LNUsageOption optionWithName:@"document" shortcut:@"d" valueRequirement:GBValueRequired description:@"The document (.dtxrec format)"],
						[LNUsageOption optionWithName:@"force" shortcut:@"f" valueRequirement:GBValueNone description:@"Force opening an incompatible recording (WARNING: may cause data damage)"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"printEntities" shortcut:@"pe" valueRequirement:GBValueNone description:@"Prints available object entities"],
						[LNUsageOption optionWithName:@"entity" shortcut:@"e" valueRequirement:GBValueRequired description:@"The entity to fetch objects of"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"printKeys" shortcut:@"pk" valueRequirement:GBValueNone description:@"Prints available keys for the specified entity"],
						[LNUsageOption optionWithName:@"printKeyFunctions" shortcut:@"pkf" valueRequirement:GBValueNone description:@"Prints supported functions (usage: function(key))"],
						[LNUsageOption optionWithName:@"keys" shortcut:@"k" valueRequirement:GBValueRequired description:@"Comma-separated collection of keys to fetch (can be entity keys or functions for the entity keys; omit to fetch all keys)"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"predicate" shortcut:@"p" valueRequirement:GBValueRequired description:@"The predicate to use for fetching (omit to fetch all objects); timestampts should always be relative"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"fetch" shortcut:@"f" valueRequirement:GBValueNone description:@"Fetch objects of the specified entities, using a predicate if specified"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"dateFormat" shortcut:@"df" valueRequirement:GBValueRequired description:@"The date format to use for displaying timestamps\n - \"relative\" - display timestamps relative to the document start (default)\n - \"datetime\" - display timestamps as absolute dates"],
						[LNUsageOption optionWithName:@"limit" valueRequirement:GBValueRequired description:@"Limit the number of returned results"],
						[LNUsageOption optionWithName:@"json" valueRequirement:GBValueNone description:@"Export the recording information data as JSON (default)"],
						[LNUsageOption optionWithName:@"plist" valueRequirement:GBValueNone description:@"Export the recording information data as property list"],
						[LNUsageOption emptyOption],
						
						[LNUsageOption optionWithName:@"version" shortcut:@"v" valueRequirement:GBValueNone description:@"Prints version"],
						]);
	
	LNUsageSetHiddenOptions(@[
							  [LNUsageOption optionWithName:@"appPath" valueRequirement:GBValueRequired description:@"The “Detox Instruments.app” to use"],
							  [LNUsageOption optionWithName:@"printAppPath" valueRequirement:GBValueNone description:@"Prints the “Detox Instruments.app” in use"],
//							  [LNUsageOption optionWithName:@"inMemory" valueRequirement:GBValueRequired description:@"Run the predicate in memory"],
							  ]);
	
	LNUsageSetAdditionalStrings(@[
								  @"",
								  @"For more features, open an issue at https://github.com/wix/DetoxInstruments",
								  @"Pull-requests are always welcome!"
								  ]);
	
	GBSettings* settings = LNUsageParseArguments(argc, argv);
	
	//	LNUsagePrintArguments(LNLogLevelStdOut);
	//	BOOL inMemory = NO;
	//	if([settings objectForKey:@"inMemory"])
	//	{
	//		inMemory = [[settings objectForKey:@"inMemory"] boolValue];
	//	}
	
	if(DTXApp == nil)
	{
		LNLog(LNLogLevelError, @"Unable to find Detox Instruments. Make sure it is installed.");
		return -1;
	}
	
	if([settings boolForKey:@"printAppPath"])
	{
		LNLog(LNLogLevelStdOut, @"%@", DTXApp.URL.path);
		return 0;
	}
	
	if([settings boolForKey:@"version"])
	{
		LNLog(LNLogLevelStdOut, @"%@ version %@", NSProcessInfo.processInfo.arguments.firstObject.lastPathComponent, DTXApp.applicationVersion);
		return 0;
	}
	
	if([settings objectForKey:@"document"] == nil)
	{
		LNUsagePrintMessage(@"No document argument specified", LNLogLevelError);
		
		return -1;
	}
	
	auto inputURL = [NSURL fileURLWithPath:[settings objectForKey:@"document"]];
	
	NSError* error;
	DTXRecordingDocument* document = [[DTXRecordingDocument alloc] initWithContentsOfURL:inputURL ofType:@"dtxrec" error:&error];
	
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
		
		if([settings boolForKey:@"printKeys"])
		{
			_DTXPrintProperties(entity);
			return 0;
		}
		
		NSMutableArray* supportedFunctions = @[@"sum", @"count", @"min", @"max", @"average"].mutableCopy;
		[supportedFunctions sortUsingSelector:@selector(compare:)];
		
		if([settings boolForKey:@"printKeyFunctions"])
		{
			LNLog(LNLogLevelStdOut, @"Available key functions:\n%@", _DTXStringFromArray(supportedFunctions));
			return 0;
		}
		
		@try
		{
			__block NSUInteger functionsCount = 0;
//			__block BOOL hasToManyRelationships;
			NSArray* propertiesToFetch = nil;
			NSString* fpString = [settings objectForKey:@"keys"];
			if(fpString)
			{
				NSMutableArray* arr = [NSMutableArray new];
				[[fpString componentsSeparatedByString:@","] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					NSString* property = [obj stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
					
					NSString* functionName;
					NSString* function;
					NSString* keyPath;
					if(_DTXParseFunction(property, &functionName, &function, &keyPath) == YES)
					{
						if([supportedFunctions containsObject:functionName] == NO)
						{
							[NSException raise:NSInvalidArgumentException format:@"Unsupported function “%@”", functionName];
						}
						
						if(entity.attributesByName[keyPath] == nil)
						{
							[NSException raise:NSInvalidArgumentException format:@"Unknown key “%@” passed to function “%@”", keyPath, functionName];
						}
						
						functionsCount++;
						NSExpressionDescription* func = [NSExpressionDescription new];
						func.name = property;
						func.expression = DTXFunctionExpression(function, @[DTXKeyPathExpression(keyPath)]);
						[arr addObject:func];
					}
					else
					{
						[arr addObject:property];
					}
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
				predicate = _DTXFixupPredicateTimestamps(predicate, document);
			}
			
			if([settings boolForKey:@"fetch"])
			{
				NSFetchRequest* fr = [NSFetchRequest new];
				fr.entity = entity;
				fr.returnsObjectsAsFaults = NO;
				fr.fetchLimit = [[settings objectForKey:@"limit"] integerValue];
				if(functionsCount > 0)
				{
					fr.resultType = NSDictionaryResultType;
					fr.propertiesToFetch = propertiesToFetch;
				}
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
	return -1;
}
