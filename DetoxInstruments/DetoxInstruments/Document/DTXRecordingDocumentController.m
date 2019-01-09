//
//  DTXRecordingDocumentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
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
	return YES;
}

- (NSArray<NSString *> *)documentClassNames
{
	return @[@"DTXRecordingDocument"];
}

- (nullable Class)documentClassForType:(NSString *)typeName
{
	return [DTXRecordingDocument class];
}

- (BOOL)presentError:(NSError *)error
{
	if([error.domain isEqualToString:@"DTXRecordingDocumentIgnoredErrorDomain"])
	{
		return NO;
	}
	
	return [super presentError:error];
}

@end
