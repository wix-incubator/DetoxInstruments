//
//  NSManagedObject+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 21/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSManagedObject+Additions.h"

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
	} callingKey:NSStringFromSelector(_cmd)];
}

- (NSDictionary*)dictionaryRepresentationForPropertyList
{
	return [self _dictionaryRepresentationWithAttributeTransformer:nil callingKey:NSStringFromSelector(_cmd)];
}

- (NSDictionary*)_dictionaryRepresentationWithAttributeTransformer:(id(^)(NSAttributeDescription* obj, id val))transformer callingKey:(NSString*)callingKey
{
	if(transformer == nil)
	{
		transformer = ^ (NSAttributeDescription* obj, id val) { return val; };
	}
	
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	NSDictionary<NSString *, NSAttributeDescription *>* attributes = [[self entity] attributesByName];
	[attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSAttributeDescription * _Nonnull obj, BOOL * _Nonnull stop) {
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

@end
