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

- (NSDictionary*)dictionaryRepresentation
{
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	NSDictionary<NSString *, NSAttributeDescription *>* attributes = [[self entity] attributesByName];
	[attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSAttributeDescription * _Nonnull obj, BOOL * _Nonnull stop) {
		if(obj.attributeType == NSDateAttributeType)
		{
			rv[key] = [__iso8601DateFormatter stringFromDate:[self valueForKey:key]];
		}
		else if(obj.attributeType == NSBinaryDataAttributeType)
		{
			rv[key] = [(NSData*)[self valueForKey:key] base64EncodedStringWithOptions:0];
		}
		else
		{
			id val = [self valueForKey:key];
			
			if(([val isKindOfClass:[NSDictionary class]] || [val isKindOfClass:[NSDictionary class]]) && [val count] == 0)
			{
				val = nil;
			}
			
			rv[key] = val;
		}
	}];
	
	NSDictionary<NSString *, NSRelationshipDescription *>* relationships = [[self entity] relationshipsByName];
	[relationships enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSRelationshipDescription * _Nonnull obj, BOOL * _Nonnull stop) {
		if([obj.userInfo[@"includeInDictionaryRepresentation"] boolValue])
		{
			id obj = [[self valueForKey:key] valueForKey:@"dictionaryRepresentation"];
			if([obj isKindOfClass:[NSOrderedSet class]])
			{
				obj = [obj array];
			}
			else if([obj isKindOfClass:[NSSet class]])
			{
				obj = [obj allObjects];
			}
			rv[key] = obj;
		}
		else if([obj.userInfo[@"flattenInDictionaryRepresentation"] boolValue])
		{
			id obj = [[self valueForKey:key] valueForKey:@"dictionaryRepresentation"];
			
			NSParameterAssert([obj isKindOfClass:[NSDictionary class]]);
			
			[rv addEntriesFromDictionary:obj];
		}
	}];
	
	return rv;
}

@end
