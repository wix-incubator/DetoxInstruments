//
//  NSManagedObjectContext+PerformQOSBlock.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "NSManagedObjectContext+PerformQOSBlock.h"

@implementation NSManagedObjectContext (PerformQOSBlock)

- (void)performBlock:(void (^)(void))block qos:(dispatch_qos_class_t)qos
{
	[self performBlock:dispatch_block_create_with_qos_class(DISPATCH_BLOCK_ENFORCE_QOS_CLASS, qos, 0, block)];
}

- (void)performBlockAndWait:(void (^)(void))block qos:(dispatch_qos_class_t)qos
{
	[self performBlockAndWait:dispatch_block_create_with_qos_class(DISPATCH_BLOCK_ENFORCE_QOS_CLASS, qos, 0, block)];
}

@end
