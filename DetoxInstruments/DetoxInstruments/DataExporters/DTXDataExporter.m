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

@end
