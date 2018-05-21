//
//  DTXRecordingDocumentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecordingDocumentController.h"
#import "DTXRecordingDocument.h"

@implementation DTXRecordingDocumentController

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
	return @[@"DTXRecordingDocument"];
}

- (nullable Class)documentClassForType:(NSString *)typeName
{
	return [DTXRecordingDocument class];
}

@end
