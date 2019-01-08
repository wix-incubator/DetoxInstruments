//
//  NSColor+CompatLayer.m
//  DetoxInstruments
//
//  Created by Leo Natan on 8/7/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "NSColor+CompatLayer.h"
@import ObjectiveC;

@implementation NSColor (CompatLayer)

+ (void)load
{
	if(NSProcessInfo.processInfo.operatingSystemVersion.minorVersion < 14)
	{
		Method m = class_getClassMethod(self, @selector(_dtx_labelColor));
		Method m2 = class_getClassMethod(self, @selector(labelColor));
		method_exchangeImplementations(m, m2);
		
		m = class_getClassMethod(self, @selector(_dtx_secondaryLabelColor));
		m2 = class_getClassMethod(self, @selector(secondaryLabelColor));
		method_exchangeImplementations(m, m2);
	}
}

+ (NSColor *)_dtx_labelColor
{
	return self.controlTextColor;
}

+ (NSColor *)_dtx_secondaryLabelColor
{
	return self.disabledControlTextColor;
}

@end
