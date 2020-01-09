//
//  DTXDataExporter.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/29/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRecordingDocument.h"

typedef enum : NSUInteger
{
	DTXDataExportTypePropertyList,
	DTXDataExportTypeJSON,
	DTXDataExportTypeCSV,
	DTXDataExportTypeHTML,
}
DTXDataExportType;

@interface DTXDataExporter : NSObject

- (instancetype)initWithDocument:(DTXRecordingDocument*)document;

@property (nonatomic, strong, readonly) DTXRecordingDocument* document;

- (NSData*)exportDataWithType:(DTXDataExportType)exportType error:(NSError**)error;

@property (class, nonatomic, readonly) BOOL supportsAsynchronousExport;
- (void)exportDataWithType:(DTXDataExportType)exportType completionHandler:(void(^)(NSData* data, NSError* error))completionHandler;

@end
