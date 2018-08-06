//
//  DTXSignpostSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostSample+CoreDataClass.h"
@import CoreData;
@import AppKit;
#import "DTXSignpostProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXSignpostSample (UIExtensions) <DTXSignpost>

+ (BOOL)hasSignpostSamplesForManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
- (NSString*)eventStatusString;
- (NSColor*)plotControllerColor;

@end

NS_ASSUME_NONNULL_END
