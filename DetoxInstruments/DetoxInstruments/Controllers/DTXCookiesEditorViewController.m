//
//  DTXCookiesEditorViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/3/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXCookiesEditorViewController.h"

static NSArray<NSString*>* __DTXCookiesBooleanAttributes;
static NSArray<NSString*>* __DTXCookiesBlacklistedAttributes;

@interface DTXCookiesEditorViewController () <LNPropertyListEditorDataTransformer, LNPropertyListEditorDelegate>

@end

@implementation DTXCookiesEditorViewController

+ (void)load
{
	__DTXCookiesBooleanAttributes = @[@"HttpOnly", @"Secure", @"sessionOnly"];
	__DTXCookiesBlacklistedAttributes = @[@"Created"];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_plistEditor.delegate = self;
	_plistEditor.dataTransformer = self;
	_plistEditor.typeColumnHidden = YES;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[_plistEditor.window makeFirstResponder:[_plistEditor valueForKey:@"outlineView"]];
}

- (void)setCookies:(NSArray<NSDictionary<NSString *,id> *> *)cookies
{
	_plistEditor.propertyList = cookies;
}

- (NSArray<NSDictionary<NSString *,id> *> *)cookies
{
	return (id)_plistEditor.propertyList;
}

+ (NSDictionary*)_emptyCookie
{
	return @{
			 @"Comment": @"",
			 @"Domain": @"",
			 @"Secure": @"FALSE",
			 @"HttpOnly": @"TRUE",
			 @"sessionOnly": @"FALSE",
			 @"Expires": [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:1 toDate:NSDate.date options:0],
			 @"Path": @"/",
			 @"Name": @"New Cookie",
			 @"Value": @"",
			 };
}

+ (NSArray<NSDictionary<NSString*, id>*>*)cookiesByFillingMissingFieldsOfCookies:(NSArray<NSDictionary<NSString*, id>*>*)cookies
{
	NSMutableArray<NSDictionary<NSString*, id>*>* mergedCookies = [NSMutableArray new];
	
	[cookies enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMutableDictionary* newCookie = self._emptyCookie.mutableCopy;
		[newCookie setValuesForKeysWithDictionary:obj];
		[newCookie removeObjectsForKeys:__DTXCookiesBlacklistedAttributes];
		[mergedCookies addObject:newCookie];
	}];
	
	return mergedCookies;
}

#pragma mark LNPropertyListEditorDataTransformer

- (NSString *)propertyListEditor:(LNPropertyListEditor *)editor displayNameForNode:(LNPropertyListNode *)node
{
	if(node.parent != editor.rootPropertyListNode)
	{
		return nil;
	}
	
	__block NSString* rv = nil;
	
	[node.children enumerateObjectsUsingBlock:^(LNPropertyListNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj.key isEqualToString:@"Name"])
		{
			rv = obj.value;
		}
	}];
	
	return rv;
}

- (id)propertyListEditor:(LNPropertyListEditor *)editor transformValueForDisplay:(LNPropertyListNode*)node
{
	if([__DTXCookiesBooleanAttributes containsObject:node.key])
	{
		return [NSNumber numberWithBool:[node.value boolValue]];
	}
	
	return nil;
}

- (id)propertyListEditor:(LNPropertyListEditor *)editor transformValueForStorage:(LNPropertyListNode *)node displayValue:(id)displayValue
{
	if([__DTXCookiesBooleanAttributes containsObject:node.key])
	{
		return [displayValue boolValue] ? @"TRUE" : @"FALSE";
	}
	
	return nil;
}

#pragma mark LNPropertyListEditorDelegate

- (void)propertyListEditor:(LNPropertyListEditor *)editor willChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey
{
	if(changeType == LNPropertyListNodeChangeTypeUpdate)
	{
		[editor reloadNode:node.parent reloadChildren:NO];
	}
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditKeyOfNode:(LNPropertyListNode*)node
{
	return NO;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditTypeOfNode:(LNPropertyListNode*)node
{
	return NO;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canDeleteNode:(LNPropertyListNode *)node
{
	return node.parent == editor.rootPropertyListNode;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canAddNewNodeInNode:(LNPropertyListNode *)node
{
	return node == editor.rootPropertyListNode;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canPasteNode:(LNPropertyListNode *)pastedNode inNode:(LNPropertyListNode *)node
{
	return pastedNode.type == LNPropertyListNodeTypeDictionary && [pastedNode childNodeForKey:@"Name"] && [pastedNode childNodeForKey:@"Domain"] && [pastedNode childNodeForKey:@"Path"];
}

- (id)propertyListEditor:(LNPropertyListEditor *)editor defaultPropertyListForAddingInNode:(LNPropertyListNode *)node
{
	return [DTXCookiesEditorViewController _emptyCookie];
}

@end
