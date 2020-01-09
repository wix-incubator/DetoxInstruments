//
//  NSFont+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/11/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "NSFont+UIAdditions.h"

@implementation NSFont (UIAdditions)

+ (NSFont *)dtx_monospacedSystemFontOfSize:(CGFloat)fontSize weight:(NSFontWeight)weight
{
	//Use embedded SF Mono to allow usage by name.
	return [NSFont fontWithDescriptor:[NSFontDescriptor fontDescriptorWithFontAttributes:@{NSFontNameAttribute: @"SF Mono", NSFontTraitsAttribute: @{NSFontWeightTrait: @(weight)}}] size:fontSize];
	
//#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101500
//	if (@available(macOS 10.15, *))
//	{
//		return [self monospacedSystemFontOfSize:fontSize weight:weight];
//	}
//	else
//	{
//#endif
//		if(weight == NSFontWeightRegular)
//		{
//			return [NSFont userFixedPitchFontOfSize:fontSize];
//		}
//
//		return [NSFontManager.sharedFontManager fontWithFamily:@"Menlo" traits:NSFixedPitchFontMask | (weight > NSFontWeightRegular ? NSBoldFontMask : 0) weight:0 size:fontSize];
//#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101500
//	}
//#endif
}

- (NSURL*)fontURL
{
	return [[self fontDescriptor] objectForKey:@"NSCTFontFileURLAttribute"];
}

@end
