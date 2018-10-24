//
//  NSObject+AttachedObjects.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 10/21/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSObject+AttachedObjects.h"
@import ObjectiveC;

@implementation NSObject (AttachedObjects)

- (void)dtx_attachObject:(nullable id)value forKey:(void*)key;
{
	objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable id)dtx_attachedObjectForKey:(void*)key;
{
	return objc_getAssociatedObject(self, key);
}

@end
