//
//  DTXDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/29/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXDataExporter.h"

@implementation DTXDataExporter

- (instancetype)initWithDocument:(DTXRecordingDocument*)document
{
	self = [super init];
	
	if(self)
	{
		_document = document;
	}
	
	return self;
}

- (NSData*)exportDataWithType:(DTXDataExportType)exportType error:(NSError**)error
{
	if(error != NULL)
	{
		*error = [NSError errorWithDomain:@"DTXErrorDomain" code:23 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unsupported export type for %@", self.className]}];
	}
	
	return nil;
}

+ (BOOL)supportsAsynchronousExport
{
	return NO;
}

- (void)exportDataWithType:(DTXDataExportType)exportType completionHandler:(void(^)(NSData* data, NSError* error))completionHandler
{
	dispatch_queue_t queue = self.class.supportsAsynchronousExport ? dispatch_get_global_queue(QOS_CLASS_UTILITY, 0) : dispatch_get_main_queue();
	
	dispatch_async(queue, ^{
		@autoreleasepool
		{
			NSError* error;
			NSData* data = [self exportDataWithType:exportType error:&error];
			
			completionHandler(data, error);
		}
	});
}

@end
