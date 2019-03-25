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

- (void)setRequestHeaders:(NSDictionary<NSString *,NSString *> *)requestHeaders
{
	self.plistEditor.propertyList = requestHeaders;
}

- (NSDictionary<NSString *,NSString *> *)requestHeaders
{
	return (id)self.plistEditor.propertyList;
}

#pragma mark LNPropertyListEditorDelegate

- (id)propertyListEditor:(LNPropertyListEditor *)editor defaultPropertyListForAddingInNode:(LNPropertyListNode*)node
{
	LNPropertyListNode* rv = [[LNPropertyListNode alloc] initWithPropertyList:@"Value"];
	rv.key = @"Header";
	
	return rv;
}

- (void)propertyListEditor:(LNPropertyListEditor *)editor didChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey
{
	[self.view.window.windowController.document updateChangeCount:NSChangeDone];
	
	[self willChangeValueForKey:@"requestHeaders"];
	[self didChangeValueForKey:@"requestHeaders"];
}

@end
