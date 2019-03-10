//
//  DTXRPQueryStringEditor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/6/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXRPQueryStringEditor.h"

@interface DTXRPQueryStringEditor ()
{
	NSURLComponents* _urlComponents;
}

@end

@implementation DTXRPQueryStringEditor

- (void)setAddress:(NSString *)address
{
	NSURLComponents* newComponents = [[NSURLComponents alloc] initWithString:address];
	if([newComponents isEqual:_urlComponents] == NO)
	{
		_urlComponents = newComponents;
		
		[self _reloadPropertyList];
	}
}

- (NSString *)address
{
	return _urlComponents.string;
}

- (void)_reloadPropertyList
{
	NSMutableDictionary* plist = [NSMutableDictionary new];
	
	[_urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[plist setObject:obj.value ?: @"" forKey:obj.name];
	}];
	
	self.plistEditor.propertyList = plist;
}

- (void)_reloadURLComponents
{
	NSMutableArray* queryItems = [NSMutableArray new];
	
	[(NSDictionary<NSString*, NSString*>*)self.plistEditor.propertyList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
		[queryItems addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
	}];
	
	[self willChangeValueForKey:@"address"];
	_urlComponents.queryItems = queryItems;
	[self didChangeValueForKey:@"address"];
}

#pragma mark LNPropertyListEditorDelegate

- (id)propertyListEditor:(LNPropertyListEditor *)editor defaultPropertyListForAddingInNode:(LNPropertyListNode*)node
{
	LNPropertyListNode* rv = [[LNPropertyListNode alloc] initWithPropertyList:@"Value"];
	rv.key = @"Query";
	
	return rv;
}

- (void)propertyListEditor:(LNPropertyListEditor *)editor willChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey
{
	[self _reloadURLComponents];
}

@end
