//
//  DTXRecordingDocumentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRecordingDocumentController.h"
#import "DTXRecordingDocument.h"
#if ! CLI
#import "DTXRequestDocument.h"
#endif

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
	if([typeName isEqualToString:@"com.wix.dtxinst.recording"] || [typeName isEqualToString:@"com.wix.dtxinst.recording.legacy"])
	{
		return DTXRecordingDocument.class;
	}
#if ! CLI
	else if([typeName isEqualToString:@"com.wix.dtxinst.request"])
	{
		return DTXRequestDocument.class;
	}
#endif
		
	return nil;
}

- (BOOL)presentError:(NSError *)error
{
	if([error.domain isEqualToString:@"DTXRecordingDocumentIgnoredErrorDomain"])
	{
		return NO;
	}
	
	return [super presentError:error];
}

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument * _Nullable, BOOL, NSError * _Nullable))completionHandler
{
	[super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:^ (NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
		
		if(document != nil && documentWasAlreadyOpen == NO)
		{
			NSWindow* window = document.windowControllers.firstObject.window;
			window.tabGroup.selectedWindow = window;
		}
		
		if(completionHandler)
		{
			completionHandler(document, documentWasAlreadyOpen, error);
		}
	}];
}

@end
