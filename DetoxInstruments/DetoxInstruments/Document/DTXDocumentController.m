//
//  DTXDocumentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDocumentController.h"
#import "DTXDocument.h"

@implementation DTXDocumentController

- (instancetype)init
{
	return [super init];
}

- (BOOL)allowsAutomaticShareMenu
{
	return NO;
}

- (NSArray<NSString *> *)documentClassNames
{
	return @[@"DTXDocument"];
}

- (nullable Class)documentClassForType:(NSString *)typeName
{
	return [DTXDocument class];
}

@end
