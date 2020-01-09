//
//  DTXThreadInfo+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXThreadInfo+CoreDataClass.h"

@interface DTXThreadInfo (UIExtensions)

+ (NSString*)mainThreadFriendlyName;

+ (DTXThreadInfo*)threadInfoForThreadNumber:(int64_t)threadNumber inManagedObjectContext:(NSManagedObjectContext*)ctx;

@property (nonatomic, readonly) NSString* friendlyName;

@end
