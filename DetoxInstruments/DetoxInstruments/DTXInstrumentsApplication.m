//
//  DTXInstrumentsApplication.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 21/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInstrumentsApplication.h"
#import "DTXRecordingDocument.h"
@import ObjectiveC;

@implementation DTXInstrumentsApplication
{
	NSAppearance* _cachedLegacyAppearance;
}

+ (void)load
{
	if(NSProcessInfo.processInfo.operatingSystemVersion.minorVersion < 14)
	{
		Method m = class_getInstanceMethod(self, @selector(_dtx_setAppearance:));
		class_addMethod(self, @selector(setAppearance:), method_getImplementation(m), method_getTypeEncoding(m));
		
		m = class_getInstanceMethod(self, @selector(_dtx_appearance));
		class_addMethod(self, @selector(appearance), method_getImplementation(m), method_getTypeEncoding(m));
		
		m = class_getInstanceMethod(self, @selector(_dtx_effectiveAppearance));
		class_addMethod(self, @selector(_dtx_effectiveAppearance), method_getImplementation(m), method_getTypeEncoding(m));
	}
}

- (void)_dtx_setAppearance:(NSAppearance *)appearance
{
	
}

- (NSAppearance *)_dtx_appearance
{
	return nil;
}

- (NSAppearance *)_dtx_effectiveAppearance
{
	if(_cachedLegacyAppearance == nil)
	{
		_cachedLegacyAppearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
	}
	
	return _cachedLegacyAppearance;
}

- (instancetype)init
{
	return [super init];
}

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender
{
	return [super sendAction:action to:target from:sender];
}

@end
