//
//  DTXInstrumentsApplicationProxy.m
//  CLI
//
//  Created by Leo Natan (Wix) on 1/8/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInstrumentsApplicationProxy.h"

DTXInstrumentsApplicationProxy* DTXApp;

@implementation DTXInstrumentsApplicationProxy
{
	NSURL* _url;
	NSString* _version;
	NSDictionary* _infoPlist;
}

+ (void)load
{
	DTXApp = [[DTXInstrumentsApplicationProxy alloc] initWithURL:[NSURL fileURLWithPath:@"/Applications/Detox Instruments.app"] error:NULL];
}

- (instancetype)initWithURL:(NSURL*)URL error:(NSError**)error
{
	if([[URL URLByAppendingPathComponent:@"Contents/Info.plist"] checkResourceIsReachableAndReturnError:error] == NO)
	{
		return nil;
	}
	
	self = [super init];
	
	if(self)
	{
		_url = URL;
		
		_infoPlist = [NSDictionary dictionaryWithContentsOfURL:[_url URLByAppendingPathComponent:@"Contents/Info.plist"]];
		_version = [NSString stringWithFormat:@"%@.%@", _infoPlist[@"CFBundleShortVersionString"], _infoPlist[@"CFBundleVersion"]];
		
		DTXApp = self;
	}
	
	return self;
}

- (NSURL *)URL
{
	return _url;
}

- (NSString *)applicationVersion
{
	return _version;
}

@end
