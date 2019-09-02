//
//  DTXInstrumentsApplicationProxy.m
//  CLI
//
//  Created by Leo Natan (Wix) on 1/8/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInstrumentsApplicationProxy.h"
#import "DTXRecordingDocument.h"

DTXInstrumentsApplicationProxy* DTXApp;

@implementation DTXInstrumentsApplicationProxy
{
	NSURL* _url;
	NSString* _version;
	NSBundle* _bundle;
	NSDictionary* _infoPlist;
}

+ (void)load
{
	NSURL* containingBundleURL = nil;
	if([NSUserDefaults.standardUserDefaults objectForKey:@"-appPath"])
	{
		containingBundleURL = [NSURL fileURLWithPath:[NSUserDefaults.standardUserDefaults objectForKey:@"-appPath"]];
		
		if(containingBundleURL != nil)
		{
			DTXApp = [[DTXInstrumentsApplicationProxy alloc] initWithURL:containingBundleURL];
		}
	}
	
	if(DTXApp == nil)
	{
		containingBundleURL = [[[[[NSURL fileURLWithPath:NSProcessInfo.processInfo.arguments.firstObject] URLByResolvingSymlinksInPath] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"../.."] URLByStandardizingPath];
		
		if(containingBundleURL != nil)
		{
			DTXApp = [[DTXInstrumentsApplicationProxy alloc] initWithURL:containingBundleURL];
		}
	}
	
	if(DTXApp == nil)
	{
		containingBundleURL = [NSURL fileURLWithPath:@"/Applications/Detox Instruments.app"];
		
		if(containingBundleURL != nil)
		{
			DTXApp = [[DTXInstrumentsApplicationProxy alloc] initWithURL:containingBundleURL];
		}
	}
}

+ (instancetype)sharedApplication
{
	return DTXApp;
}

- (instancetype)initWithURL:(NSURL*)URL
{
	NSBundle* bundle = [NSBundle bundleWithURL:URL];
	if(bundle == nil || [[bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"] isEqualToString:@"com.wix.DetoxInstruments"] == NO)
	{
		return nil;
	}
	
	self = [super init];
	
	if(self)
	{
		_url = URL;

		_infoPlist = bundle.infoDictionary;
		_version = [NSString stringWithFormat:@"%@.%@", _infoPlist[@"CFBundleShortVersionString"], _infoPlist[@"CFBundleVersion"]];
		_bundle = bundle;
		
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

- (NSArray<NSBundle*>*)bundlesForObjectModel
{
	return @[_bundle];
}

@end

@implementation DTXInstrumentsUtils

+ (NSString *)applicationVersion
{
	return DTXApp.applicationVersion;
}

+ (NSArray<NSBundle*>*)bundlesForObjectModel
{
	return DTXApp.bundlesForObjectModel;
}

@end
