//
//  DTXKeyedDataExporter.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/29/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXDataExporter.h"

@interface DTXKeyedDataExporter : DTXDataExporter

- (NSArray<NSString*>*)exportedKeyPaths;
- (NSArray<NSString*>*)titles;
- (NSFetchRequest*)fetchRequest;
- (id(^)(id))transformer;

@end
