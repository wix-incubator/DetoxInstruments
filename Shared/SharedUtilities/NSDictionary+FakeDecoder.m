//
//  NSDictionary+FakeDecoder.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "NSDictionary+FakeDecoder.h"

@implementation NSDictionary (FakeDecoder)

- (id)decodeObjectForKey:(NSString*)key
{
	return self[key];
}

@end
