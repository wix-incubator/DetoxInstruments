//
//  DTXInstrumentsApplication+CompatLayer.m
//  DetoxInstruments
//
//  Created by Leo Natan on 8/7/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInstrumentsApplication+CompatLayer.h"
@import ObjectiveC;

static NSAppearance* _cachedLegacyAppearance;

@implementation DTXInstrumentsApplication (CompatLayer)

+ (void)load
{
	if(NSProcessInfo.processInfo.operatingSystemVersion.minorVersion < 14)
	{
		Method m = class_getInstanceMethod(self, @selector(_dtx_setAppearance:));
		class_addMethod(self, @selector(setAppearance:), method_getImplementation(m), method_getTypeEncoding(m));
		
		m = class_getInstanceMethod(self, @selector(_dtx_appearance));
		class_addMethod(self, @selector(appearance), method_getImplementation(m), method_getTypeEncoding(m));
		
		m = class_getInstanceMethod(self, @selector(_dtx_effectiveAppearance));
		class_addMethod(self, @selector(effectiveAppearance), method_getImplementation(m), method_getTypeEncoding(m));
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


@end
