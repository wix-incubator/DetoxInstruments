//
//  DTXInstrumentsApplication.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 21/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInstrumentsApplication.h"
#import "DTXRecordingDocument.h"

DTXInstrumentsApplication* DTXApp;

@implementation DTXInstrumentsApplication

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		DTXApp = self;
	}
	
	return self;
}

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender
{
	return [super sendAction:action to:target from:sender];
}

- (NSString *)applicationVersion
{
	static NSString* rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = [NSString stringWithFormat:@"%@.%@", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
	});
	
	return rv;
}

- (NSArray<NSBundle*>*)bundlesForObjectModel
{
	static NSArray* rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = @[[NSBundle bundleForClass:DTXRecording.class]];
	});
	
	return rv;
}

- (BOOL)isUnsupportedVersion
{
	static BOOL rv;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		rv = [NSBundle.mainBundle.bundlePath containsString:@"node_modules/"];
	});
	
	return rv;
}

@end
