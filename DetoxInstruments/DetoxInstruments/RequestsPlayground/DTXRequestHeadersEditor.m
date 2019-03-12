//
//  DTXRequestHeadersEditor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/4/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRequestHeadersEditor.h"

@interface DTXRequestHeadersEditor ()

@end

@implementation DTXRequestHeadersEditor
{
	BOOL _readOnly;
}

- (void)setRequestHeaders:(NSDictionary<NSString *,NSString *> *)requestHeaders
{
	self.plistEditor.propertyList = requestHeaders;
}

- (NSDictionary<NSString *,NSString *> *)requestHeaders
{
	return (id)self.plistEditor.propertyList;
}

- (void)setHeadersWithResponse:(NSHTTPURLResponse*)response
{
	_readOnly = YES;

	self.plistEditor.propertyList = response.allHeaderFields;
}

#pragma mark LNPropertyListEditorDelegate

- (id)propertyListEditor:(LNPropertyListEditor *)editor defaultPropertyListForAddingInNode:(LNPropertyListNode*)node
{
	LNPropertyListNode* rv = [[LNPropertyListNode alloc] initWithPropertyList:@"Value"];
	rv.key = @"Header";
	
	return rv;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditKeyOfNode:(LNPropertyListNode*)node
{
	return _readOnly == NO;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditValueOfNode:(LNPropertyListNode*)node
{
	return _readOnly == NO;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canDeleteNode:(LNPropertyListNode*)node
{
	return _readOnly == NO;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canAddNewNodeInNode:(LNPropertyListNode*)node
{
	return _readOnly == NO;
}

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canPasteNode:(LNPropertyListNode*)pastedNode inNode:(LNPropertyListNode*)node
{
	return _readOnly == NO;
}

@end
