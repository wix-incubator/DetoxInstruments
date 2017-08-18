//
//  NSManagedObject+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 21/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSManagedObject+Additions.h"
@import Darwin;

static NSDateFormatter* __iso8601DateFormatter;

@implementation NSManagedObject (Additions)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__iso8601DateFormatter = [NSDateFormatter new];
		__iso8601DateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSZZZZZ";
	});
}

- (NSDictionary*)dictionaryRepresentationForJSON
{
	return [self _dictionaryRepresentationWithAttributeTransformer:^id(NSAttributeDescription* obj, id val) {
		if(obj.attributeType == NSDateAttributeType)
		{
			val = [__iso8601DateFormatter stringFromDate:val];
		}
		else if(obj.attributeType == NSBinaryDataAttributeType)
		{
			val = [(NSData*)val base64EncodedStringWithOptions:0];
		}
		
		return val;
	} callingKey:NSStringFromSelector(_cmd) onlyInKeys:nil];
}

- (NSDictionary*)dictionaryRepresentationForPropertyList
{
	return [self _dictionaryRepresentationWithAttributeTransformer:nil callingKey:NSStringFromSelector(_cmd) onlyInKeys:nil];
}

- (NSDictionary<NSString *,id> *)dictionaryRepresentationOfChangedValuesForPropertyList
{
	return [self _dictionaryRepresentationWithAttributeTransformer:nil callingKey:@"dictionaryRepresentationForPropertyList" onlyInKeys:[[self changedValuesForCurrentEvent] allKeys]];
}

- (NSDictionary*)_dictionaryRepresentationWithAttributeTransformer:(id(^)(NSAttributeDescription* obj, id val))transformer callingKey:(NSString*)callingKey onlyInKeys:(NSArray<NSString*>*)filteredKeys
{
	if(transformer == nil)
	{
		transformer = ^ (NSAttributeDescription* obj, id val) { return val; };
	}
	
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	rv[@"__dtx_className"] = self.entity.managedObjectClassName;
	rv[@"__dtx_entityName"] = self.entity.name;
	
	NSDictionary<NSString *, NSAttributeDescription *>* attributes = [[self entity] attributesByName];
	[attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSAttributeDescription * _Nonnull obj, BOOL * _Nonnull stop) {
		if(filteredKeys != nil && [filteredKeys containsObject:key] == NO)
		{
			return;
		}
		
		id val = transformer(obj, [self valueForKey:key]);
		
		if(([val isKindOfClass:[NSDictionary class]] || [val isKindOfClass:[NSArray class]]) && [val count] == 0)
		{
			val = nil;
		}
		
		if([obj.userInfo[@"suppressInDictionaryRepresentationIfZero"] boolValue] && [val isKindOfClass:[NSNumber class]] && [val isEqualToNumber:@0])
		{
			val = nil;
		}
		
		rv[key] = val;
	}];
	
	NSDictionary<NSString *, NSRelationshipDescription *>* relationships = [[self entity] relationshipsByName];
	[relationships enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSRelationshipDescription * _Nonnull obj, BOOL * _Nonnull stop) {
		if(filteredKeys != nil && [filteredKeys containsObject:key] == NO)
		{
			return;
		}
		
		NSString* outputKey = key;
		
		if(obj.userInfo[@"transformedDictionaryOutputKey"] != nil)
		{
			outputKey = obj.userInfo[@"transformedDictionaryOutputKey"];
		}
		
		if([obj.userInfo[@"includeInDictionaryRepresentation"] boolValue])
		{
			id val = [[self valueForKey:key] valueForKey:callingKey];
			if([val isKindOfClass:[NSOrderedSet class]])
			{
				val = [val array];
			}
			else if([val isKindOfClass:[NSSet class]])
			{
				val = [val allObjects];
			}
			
			if(obj.userInfo[@"sortArrayByKeyPath"] && [val isKindOfClass:[NSArray class]])
			{
				val = [val sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:obj.userInfo[@"sortArrayByKeyPath"] ascending:YES]]];
			}
			
			rv[outputKey] = val;
		}
		else if([obj.userInfo[@"flattenInDictionaryRepresentation"] boolValue])
		{
			id val = [[self valueForKey:key] valueForKey:callingKey];
			
			if(val == nil)
			{
				return;
			}
			
			NSParameterAssert([val isKindOfClass:[NSDictionary class]]);
			
			[rv addEntriesFromDictionary:val];
		}
		else if(obj.userInfo[@"includeKeyPathInDictionaryRepresentation"] != nil)
		{
			id keyPathVal = [[self valueForKey:key] valueForKeyPath:obj.userInfo[@"includeKeyPathInDictionaryRepresentation"]];
			rv[outputKey] = keyPathVal;
		}
	}];
	
	return rv;
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
				[obj enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					NSString* className = [obj respondsToSelector:@selector(objectForKey:)] ? [obj objectForKey:@"__dtx_className"] : nil;
					if(className == nil)
					{
						className = relationship.destinationEntity.managedObjectClassName;
					}
					
					Class cls = NSClassFromString(className);
					__kindof NSManagedObject* managedObject = [[cls alloc] initWithPropertyListDictionaryRepresentation:obj context:self.managedObjectContext];
					[transformed addObject:managedObject];
				}];
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
		
		[self setValue:obj forKey:key];
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
