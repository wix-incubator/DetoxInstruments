//
//  NSAppearance+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSAppearance+UIAdditions.h"

@implementation NSAppearance (UIAdditions)

- (BOOL)isDarkAppearance
{
	if([self.name isEqualToString:@"NSAppearanceNameFunctionRow"])
	{
		return YES;
	}
	
	if (@available(macOS 10.14, *)) {
		NSAppearanceName appearanceName = [self bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
		
		return [appearanceName isEqualToString:NSAppearanceNameDarkAqua];
	} else {
		return NO;
	}
}

- (BOOL)isTouchBarAppearance
{
	if([self.name isEqualToString:@"NSAppearanceNameFunctionRow"])
	{
		return YES;
	}
	
	return NO;
}

- (void)performBlockAsCurrentAppearance:(void(^)(void))block
{
	NSAppearance* current = NSAppearance.currentAppearance;
	NSAppearance.currentAppearance = self;
	block();
	NSAppearance.currentAppearance = current;
}

@end
