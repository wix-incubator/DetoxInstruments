//
//  NSURL+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/12/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "NSURL+UIAdditions.h"

@implementation NSURL (UIAdditions)

+ (instancetype)temporaryDirectoryURL
{
	return [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
	
//	return [NSFileManager.defaultManager URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:[NSURL fileURLWithPath:@"/"] create:YES error:NULL];
}

@end
