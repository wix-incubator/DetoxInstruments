//
//  NSManagedObjectContext+PerformQOSBlock.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (PerformQOSBlock)

- (void)performBlock:(void (^)(void))block qos:(dispatch_qos_class_t)qos;
- (void)performBlockAndWait:(void (^)(void))block qos:(dispatch_qos_class_t)qos;

@end
