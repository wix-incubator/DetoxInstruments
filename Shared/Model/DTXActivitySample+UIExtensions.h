//
//  DTXActivitySample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSignpostSample+UIExtensions.h"
#import "DTXActivitySample+CoreDataClass.h"
@import CoreData;
@import AppKit;
@class DTXRecording;
#import "DTXSignpostProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXActivitySample (UIExtensions) <DTXSignpost>

+ (BOOL)hasActivitySamplesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
#if ! CLI
- (NSColor*)plotControllerColor;
#endif

@end

NS_ASSUME_NONNULL_END
