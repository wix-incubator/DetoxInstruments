//
//  DTXSignpostSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSignpostSample+CoreDataClass.h"
@import CoreData;
@import AppKit;
@class DTXRecording;
#import "DTXSignpostProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXSignpostSample (UIExtensions) <DTXSignpost>

+ (BOOL)hasSignpostSamplesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
- (NSString*)eventTypeString;
- (NSString*)eventStatusString;
#if ! CLI
- (NSColor*)plotControllerColor;
#endif
- (NSDate*)defactoEndTimestamp;

@end

NS_ASSUME_NONNULL_END
