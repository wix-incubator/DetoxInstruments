//
//  DTXSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSample+UIExtensions.h"

@implementation DTXSample (UIExtensions)

- (NSString *)descriptionForUI
{
	return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Sample", @""), NSStringFromClass([self class])];
}

- (NSImage*)imageForUI
{
	return [NSImage imageNamed:@"networkActivity_tb"];
}

- (BOOL)isKind
{
	return YES;
}

@end
