//
//  NSAppearance+UIAdditions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "NSAppearance+UIAdditions.h"

@implementation NSAppearance (UIAdditions)

- (BOOL)isAppearanceDark
{
	return self == [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
}

@end
