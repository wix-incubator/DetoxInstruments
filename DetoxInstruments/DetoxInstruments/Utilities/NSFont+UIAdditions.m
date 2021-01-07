//
//  NSFont+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/11/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "NSFont+UIAdditions.h"

@implementation NSFont (UIAdditions)

- (NSURL*)fontURL
{
	return [[self fontDescriptor] objectForKey:@"NSCTFontFileURLAttribute"];
}

@end
