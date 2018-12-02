//
//  DTXDataExporter.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/29/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRecordingDocument.h"

typedef enum : NSUInteger
{
	DTXDataExportTypePropertyList,
	DTXDataExportTypeJSON,
	DTXDataExportTypeCSV,
}
DTXDataExportType;

@interface DTXDataExporter : NSObject

- (instancetype)initWithDocument:(DTXRecordingDocument*)document;

@property (nonatomic, strong) DTXRecordingDocument* document;

- (NSData*)exportDataWithType:(DTXDataExportType)exportType error:(NSError**)error;

@end
