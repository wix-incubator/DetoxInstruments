//
//  NSKeyedUnarchiver+QuickDecodingSecureCoding.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/13/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "NSKeyedUnarchiver+QuickDecodingSecureCoding.h"

@implementation NSKeyedUnarchiver (QuickDecodingSecureCoding)

+ (nullable id)dtx_unarchiveObjectWithData:(NSData *)data requiringSecureCoding:(BOOL)requiresSecureCoding error:(NSError **)error
{
	NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:error];
	unarchiver.requiresSecureCoding = requiresSecureCoding;
	return [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
}

@end
