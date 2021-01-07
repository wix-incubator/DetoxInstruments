//
//  NSManagedObject+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 21/05/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "NSManagedObject+Additions.h"
#import "DTXSample+Additions.h"
#import "DTXRecording+Additions.h"
@import Darwin;

static NSDateFormatter* __iso8601DateFormatter;

@implementation NSManagedObject (Additions)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__iso8601DateFormatter = [NSDateFormatter new];
		__iso8601DateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSZZZZZ";
		
		DTXNSManagedObjectToJSONDictionaryRepresentationTransformer = ^ id(__kindof NSPropertyDescription* obj, id val) {
			if([obj isKindOfClass:NSAttributeDescription.class])
			{
				NSAttributeDescription* attrObj = obj;
				
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
				if(attrObj.attributeType == NSURIAttributeType || [val isKindOfClass:NSURL.class])
#pragma clang diagnostic pop
				{
					val = [val absoluteString];
				}
				else if(attrObj.attributeType == NSDateAttributeType)
				{
					val = [__iso8601DateFormatter stringFromDate:val];
				}
				else if(attrObj.attributeType == NSBinaryDataAttributeType)
				{
					val = [(NSData*)val base64EncodedStringWithOptions:0];
				}
			}
			
			return val;
		};
		
		DTXNSManagedObjectToPropertyListDictionaryRepresentationTransformer = ^ id(__kindof NSPropertyDescription* obj, id val) { return val; };
	});
}

- (NSDictionary*)cleanDictionaryRepresentationForJSON
{
	NSMutableDictionary* rv = [self _dictionaryRepresentationWithAttributeTransformer:DTXNSManagedObjectToJSONDictionaryRepresentationTransformer callingKey:NSStringFromSelector(_cmd) onlyInKeys:nil includeMetadata:NO cleanIfNeeded:YES];
	
	return rv;
}

- (NSDictionary*)cleanDictionaryRepresentationForPropertyList
{
	NSMutableDictionary* rv = [self _dictionaryRepresentationWithAttributeTransformer:nil callingKey:NSStringFromSelector(_cmd) onlyInKeys:nil includeMetadata:NO cleanIfNeeded:YES];
	
	return rv;
}

- (NSDictionary*)dictionaryRepresentationForJSON
{
	return [self _dictionaryRepresentationWithAttributeTransformer:DTXNSManagedObjectToJSONDictionaryRepresentationTransformer callingKey:NSStringFromSelector(_cmd) onlyInKeys:nil includeMetadata:YES cleanIfNeeded:YES];
}

- (NSDictionary*)dictionaryRepresentationForPropertyList
{
	return [self _dictionaryRepresentationWithAttributeTransformer:nil callingKey:NSStringFromSelector(_cmd) onlyInKeys:nil includeMetadata:YES cleanIfNeeded:NO];
}

- (NSDictionary<NSString *,id> *)dictionaryRepresentationOfChangedValuesForPropertyList
{
	return [self _dictionaryRepresentationWithAttributeTransformer:nil callingKey:@"dictionaryRepresentationForPropertyList" onlyInKeys:[[self changedValuesForCurrentEvent] allKeys] includeMetadata:YES cleanIfNeeded:NO];
}

id(^DTXNSManagedObjectToJSONDictionaryRepresentationTransformer)(NSPropertyDescription* obj, id val);
id(^DTXNSManagedObjectToPropertyListDictionaryRepresentationTransformer)(NSPropertyDescription* obj, id val);

static void __DTXCleanIfNeeded(id self, NSMutableDictionary* rv)
{
//	if([self isKindOfClass:DTXSample.class])
//	{
//		Class cls = [DTXSample classFromSampleType:(DTXSampleType)(((DTXSample*)self).sampleType)];
//		NSString* sampleType = [NSStringFromClass(cls) substringFromIndex:3];
//		sampleType = [NSString stringWithFormat:@"%@%@", [[sampleType substringToIndex:1] lowercaseString], [sampleType substringFromIndex:1]];
//		
//		rv[@"sampleType"] = sampleType;
//	}
	
	if([self isKindOfClass:DTXRecording.class])
	{
		NSMutableDictionary* config = [rv[@"profilingConfiguration"] mutableCopy];
		NSURL* url = config[@"recordingFileURL"];
		if(url)
		{
			config[@"recordingFileURL"] = url.path;
		}
		rv[@"profilingConfiguration"] = config;
	}
}

static id _DTXNSManagedObjectDictionaryRepresentationObjectOrCollection(NSPropertyDescription* obj, id val, NSArray* filteredKeys, id(^transformer)(NSPropertyDescription* obj, id val), BOOL includeMetadata, BOOL cleanIfNeeded)
{
	id rv = nil;
	
	if([val isKindOfClass:NSOrderedSet.class])
	{
		rv = [val array];
	}
	else if([val isKindOfClass:NSSet.class])
	{
		rv = [val allObjects];
	}
	else
	{
		rv = val;
	}
	
	if([rv isKindOfClass:NSArray.class])
	{
		NSMutableArray* transformedObjs = [NSMutableArray new];
		[rv enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			NSEntityDescription* entity = [obj respondsToSelector:@selector(entity)] ? [obj entity] : nil;
			id transformedObj = DTXNSManagedObjectDictionaryRepresentation(obj, entity, filteredKeys, transformer, includeMetadata, cleanIfNeeded);
			[transformedObjs addObject:transformedObj];
		}];
		
		if(obj.userInfo[@"sortArrayByKeyPath"])
		{
			[transformedObjs sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:obj.userInfo[@"sortArrayByKeyPath"] ascending:YES]]];
		}
		
		rv = transformedObjs;
	}
	else
	{
		NSEntityDescription* entity = [rv respondsToSelector:@selector(entity)] ? [rv entity] : nil;
		rv = DTXNSManagedObjectDictionaryRepresentation(rv, entity, filteredKeys, transformer, includeMetadata, cleanIfNeeded);
	}
	
	return rv;
}

NSMutableArray* DTXArrayOfNSManagedObjectDictionaryRepresentations(NSArray* objects, NSArray* filteredKeys, id(^transformer)(NSPropertyDescription* obj, id val), BOOL includeMetadata, BOOL cleanIfNeeded)
{
	return _DTXNSManagedObjectDictionaryRepresentationObjectOrCollection(nil, objects, filteredKeys, transformer, includeMetadata, cleanIfNeeded);
}

NSMutableDictionary* DTXNSManagedObjectDictionaryRepresentation(id self, NSEntityDescription* entity, NSArray* filteredKeys, id(^transformer)(NSPropertyDescription* obj, id val), BOOL includeMetadata, BOOL cleanIfNeeded)
{
	if(transformer == nil)
	{
		transformer = ^ (NSPropertyDescription* obj, id val) { return val; };
	}
	
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	if(includeMetadata)
	{
		rv[@"__dtx_className"] = entity.managedObjectClassName;
		rv[@"__dtx_entityName"] = entity.name;
	}
	
	NSDictionary<NSString *, __kindof NSPropertyDescription *>* properties = entity.propertiesByName;
	[properties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof NSPropertyDescription * _Nonnull obj, BOOL * _Nonnull stop) {
		@autoreleasepool
		{
			if(filteredKeys != nil && [filteredKeys containsObject:key] == NO)
			{
				return;
			}
			
			NSString* outputKey = key;
			
			if([obj isKindOfClass:NSRelationshipDescription.class])
			{
				if([obj.userInfo[@"includeInDictionaryRepresentation"] boolValue])
				{
					rv[outputKey] = _DTXNSManagedObjectDictionaryRepresentationObjectOrCollection(obj, [self valueForKey:key], nil, transformer, includeMetadata, cleanIfNeeded);
				}
				else if(obj.userInfo[@"includeKeyPathInDictionaryRepresentation"] != nil)
				{
					id keyPathVal = [[self valueForKey:key] valueForKeyPath:obj.userInfo[@"includeKeyPathInDictionaryRepresentation"]];
					rv[outputKey] = keyPathVal;
				}
			}
			else if([obj isKindOfClass:NSFetchedPropertyDescription.class] && [obj.userInfo[@"includeInDictionaryRepresentation"] boolValue])
			{
				NSCParameterAssert([self isKindOfClass:NSManagedObject.class]);
				
				NSFetchedPropertyDescription* fetchedObj = obj;
				NSFetchRequest* fr = [fetchedObj.fetchRequest copy];
				fr.predicate = [fr.predicate predicateWithSubstitutionVariables:@{@"FETCH_SOURCE": self}];
				
				if(obj.userInfo[@"sortArrayByKeyPath"])
				{
					fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:obj.userInfo[@"sortArrayByKeyPath"] ascending:YES]];
				}
				
				id val = [((NSManagedObject*)self).managedObjectContext executeFetchRequest:fr error:NULL];
				
				rv[outputKey] = _DTXNSManagedObjectDictionaryRepresentationObjectOrCollection(obj, val, nil, transformer, includeMetadata, cleanIfNeeded);
			}
			else if([obj isKindOfClass:NSAttributeDescription.class])
			{
				id val = transformer(obj, [self valueForKey:key]);
				
				if(([val isKindOfClass:[NSDictionary class]] || [val isKindOfClass:[NSArray class]]) && [val count] == 0)
				{
					val = nil;
				}
				
				if([obj.userInfo[@"suppressInDictionaryRepresentationIfZero"] boolValue] && [val isKindOfClass:[NSNumber class]] && [val isEqualToNumber:@0])
				{
					val = nil;
				}
				
				if([val isKindOfClass:NSNumber.class] && [obj isKindOfClass:NSAttributeDescription.class] && ((NSAttributeDescription*)obj).attributeType == NSBooleanAttributeType)
				{
					val = [NSNumber numberWithBool:[val boolValue]];
				}
				
				rv[outputKey] = val;
			}
		}
	}];
	
	[filteredKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:NSExpressionDescription.class] == NO)
		{
			return;
		}
		
		NSExpressionDescription* expr = obj;
		
		rv[expr.name] = [self objectForKey:expr.name];
	}];
	
	if(cleanIfNeeded)
	{
		__DTXCleanIfNeeded(self, rv);
	}
	
	return rv;
}

- (NSMutableDictionary*)_dictionaryRepresentationWithAttributeTransformer:(id(^)(NSPropertyDescription* obj, id val))transformer callingKey:(NSString*)callingKey onlyInKeys:(NSArray<NSString*>*)filteredKeys includeMetadata:(BOOL)includeMetadata cleanIfNeeded:(BOOL)cleanIfNeeded
{
	return DTXNSManagedObjectDictionaryRepresentation(self, self.entity, filteredKeys, transformer, includeMetadata, cleanIfNeeded);
}

- (void)updateWithPropertyListDictionaryRepresentation:(NSDictionary *)propertyListDictionaryRepresentation
{
	[propertyListDictionaryRepresentation enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		if([key isEqualToString:@"__dtx_className"] || [key isEqualToString:@"__dtx_entityName"])
		{
			return;
		}
		
		NSRelationshipDescription* relationship = self.entity.relationshipsByName[key];
		if(relationship)
		{
			if(relationship.userInfo[@"includeKeyPathInDictionaryRepresentation"])
			{
				NSFetchRequest* fr = [[NSFetchRequest alloc] initWithEntityName:relationship.destinationEntity.name];
				fr.predicate = [NSPredicate predicateWithFormat:@"%K == %@", relationship.userInfo[@"includeKeyPathInDictionaryRepresentation"], obj];
				NSArray* potential = [self.managedObjectContext executeFetchRequest:fr error:NULL];
				obj = potential.firstObject;
			}
			else if(relationship.isToMany == YES)
			{
				NSMutableArray* transformed = [NSMutableArray new];
				
				for (id item in obj) {
					NSString* className = [item respondsToSelector:@selector(objectForKey:)] ? [item objectForKey:@"__dtx_className"] : nil;
					if(className == nil)
					{
						className = relationship.destinationEntity.managedObjectClassName;
					}
					
					Class cls = NSClassFromString(className);
					__kindof NSManagedObject* managedObject = [[cls alloc] initWithPropertyListDictionaryRepresentation:item context:self.managedObjectContext];
					[transformed addObject:managedObject];
				}
				
				obj = transformed;
				
				if(relationship.ordered == NO)
				{
					obj = [NSSet setWithArray:obj];
				}
				
				if(relationship.ordered == YES)
				{
					obj = [NSOrderedSet orderedSetWithArray:obj];
				}
			}
			else
			{
				NSString* className = [obj respondsToSelector:@selector(objectForKey:)] ? [obj objectForKey:@"__dtx_className"] : nil;
				if(className == nil)
				{
					className = relationship.destinationEntity.managedObjectClassName;
				}
				
				Class cls = NSClassFromString(className);
				obj = [[cls alloc] initWithPropertyListDictionaryRepresentation:obj context:self.managedObjectContext];
			}
		}
		
		if(self.entity.propertiesByName[key])
		{
			[self setValue:obj forKey:key];
		}
	}];
}

- (instancetype)initWithPropertyListDictionaryRepresentation:(NSDictionary *)propertyListDictionaryRepresentation context:(NSManagedObjectContext *)moc
{
	if(self.entity != nil)
	{
		self = [self initWithContext:moc];
	}
	else
	{
		NSString* entityName = [NSStringFromClass(self.class) substringFromIndex:3];
		self = [self initWithEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc] insertIntoManagedObjectContext:moc];
	}
	
	if(self)
	{
		[self updateWithPropertyListDictionaryRepresentation:propertyListDictionaryRepresentation];
	}
	
	return self;
}

@end
