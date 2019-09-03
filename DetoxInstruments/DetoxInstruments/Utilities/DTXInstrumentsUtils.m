//
//  DTXInstrumentsUtils.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/1/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInstrumentsUtils.h"

@implementation DTXInstrumentsUtils

+ (NSString *)applicationVersion
{
	static NSString* rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = [NSString stringWithFormat:@"%@.%@", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
	});
	
	return rv;
}

+ (NSArray<NSBundle*>*)bundlesForObjectModel
{
	static NSArray* rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = @[[NSBundle bundleForClass:DTXRecording.class]];
	});
	
	return rv;
}

+ (BOOL)isUnsupportedVersion
{
	static BOOL rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = [NSBundle.mainBundle.bundlePath containsString:@"node_modules/"];
	});
	
	return rv;
}

@end
