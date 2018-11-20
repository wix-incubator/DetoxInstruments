//
//  DTXPasteboardItem.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/11/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPasteboardItem.h"

NSString* const DTXColorPasteboardType = @"com.wix.DTXColor";

@implementation DTXPasteboardItem
{
	NSMutableOrderedSet* _types;
	NSMutableDictionary<NSString*, id>* _values;
}

@synthesize types=_types;

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_types = [NSMutableOrderedSet new];
		_values = [NSMutableDictionary new];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	if(self)
	{
		_types = [aDecoder decodeObjectForKey:@"_types"];
		_values = [aDecoder decodeObjectForKey:@"_values"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_types forKey:@"_types"];
	[aCoder encodeObject:_values forKey:@"_values"];
}

- (void)addType:(NSString*)type value:(id)value
{
	if([_types containsObject:type])
	{
		return;
	}
	
	[_types addObject:type];
	_values[type] = value;
}

- (void)addType:(NSString*)type data:(NSData*)data
{
	[self addType:type value:data];
}

- (id)valueForType:(NSString*)type
{
	return _values[type];
}

- (NSData*)dataForType:(NSString*)type
{
	return _values[type];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ types: %@", super.description, _types];
}

@end
